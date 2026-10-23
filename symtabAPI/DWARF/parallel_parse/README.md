Parse DWARF types in parallel and compare with a serial parse.

`DwarfWalker::parse()` hands the compilation units to OpenMP workers. When all
the workers share one libdw handle, the walk intermittently loses types:
libdw is not safe for concurrent use of a handle, a failed `dwarf_child()`
unwinds the whole unit, and nothing reports it. With dwz output it can also
crash, because the partial units that hold the shared types also hold
libdw's `dwarf_getlocations()` cache, which workers in different units then
insert into at once
([#2410](https://github.com/dyninst/dyninst/issues/2410)).

A supplementary file from multi-file dwz (`.gnu_debugaltlink`) is shared state
too: walkers following `DW_FORM_GNU_ref_alt` into it grow its lazily built unit
tree at once and corrupt it
([#914](https://github.com/dyninst/dyninst/issues/914)), which can crash or
leave a walker looping forever in `tfind()`.

The binaries are built to make these likely: 24 compilation units that each use
15 of the same 40 structs and 40 unions.

| binary                  | dwz          | where the shared types are |
|-------------------------|--------------|----------------------------|
| `shared_types_dwz.so`   | single-file  | partial units in its own `.debug_info` |
| `shared_types_alt_a.so` | multi-file   | `shared_types.dwz`, named by `.gnu_debugaltlink` |
| `shared_types_alt_b.so` | multi-file   | `shared_types.dwz`; exists so that dwz has two files to share types between |

| property                       | `shared_types_dwz.so` | `shared_types_alt_a.so` |
|--------------------------------|-------------|-------------|
| compilation units              | 24          | 12          |
| partial units                  | 78          | 34, and 53 in `shared_types.dwz` |
| `DW_TAG_imported_unit`         | 429         | 202         |
| types, fields (serial parse)   | 5495, 19106 | 2853, 10235 |

With 32 OpenMP threads, even on two CPUs, a parse of `shared_types_dwz.so` on a
shared handle found fewer types than the serial parse in most runs (16 of 20 to
30 of 30, depending on load), with or without a lock around
`dwarf_getlocations()`, and one of 74 parses tried crashed. A parallel parse of
`shared_types_alt_a.so` on a shared supplementary handle was wrong or crashed
in 58 of 60 runs. With private handles for every worker, both always matched
the serial parse.

## Building

`src/` holds the generated sources, written by

```
./gen.py src 40 24 15
```

(structs, units, structs used per unit; the generator is seeded, so it should
rewrite the same files, but `src/` is the reference). `build.sh` then
compiles and runs dwz, with
`CFLAGS="-O2 -g -fPIC -shared -ffile-prefix-map=$PWD/src=/src -gno-record-gcc-switches"`:

```
gcc $CFLAGS src/cu*.c -o shared_types_dwz.so
dwz shared_types_dwz.so

gcc $CFLAGS src/cu[0-9].c src/cu1[01].c -o shared_types_alt_a.so
gcc $CFLAGS src/cu1[2-9].c src/cu2[0-3].c -o shared_types_alt_b.so
dwz -m shared_types.dwz -M shared_types.dwz shared_types_alt_a.so shared_types_alt_b.so
```

`-M` records the supplementary file's name relative to the libraries, so it is
found next to them wherever the repository is checked out.

The binary was built with gcc 8.5.0 (Red Hat 8.5.0-18) and dwz 0.12.
