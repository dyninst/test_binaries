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
too: walkers following `DW_FORM_GNU_ref_alt` into it share its units. They
insert into those units' `dwarf_getlocations()` caches at once, as above, which
can crash a parse or leave a walker looping forever in `tfind()`, and they grow
the file's lazily built unit tree at once, which can corrupt it and crash
([#914](https://github.com/dyninst/dyninst/issues/914)).

## The binaries

24 compilation units that each use 15 of the same 40 structs and 40 unions,
processed by dwz in its two layouts. These are dwz's layouts, not split DWARF:
every unit's DWARF is in the library itself or, for the multi-file layout, in
the one supplementary file; there are no `.dwo` files.

| binary | DWARF | dwz | shared types in |
|---|---|---|---|
| `shared_types_dwz.so` | 4 | single-file | its partial units |
| `shared_types_alt_a.so` | 4 | multi-file | `shared_types.dwz` |
| `shared_types_alt_b.so` | 4 | multi-file | `shared_types.dwz` |
| `shared_types_dwz5.so` | 5 | single-file | its partial units |
| `shared_types_alt5_a.so` | 5 | multi-file | `shared_types5.dwz` |
| `shared_types_alt5_b.so` | 5 | multi-file | `shared_types5.dwz` |

The `_b` libraries exist so that dwz has two files to share types between;
the tests use `_a`. Each library names its supplementary file relative to
itself (`dwz -M`), so it is found next to it wherever the repository is
checked out.

What each one contains, counted with `eu-readelf --debug-dump=info`, and the
types and fields of a serial parse with Dyninst:

| | `dwz.so` | `alt_a.so` | `dwz5.so` | `alt5_a.so` |
|---|---|---|---|---|
| compilation units | 24 | 12 | 24 | 12 |
| partial units | 77 | 34 | 77 | 35 |
| in the `.dwz` | - | 53 | - | 36 |
| `DW_TAG_imported_unit` | 440 | 202 | 426 | 202 |
| types | 5456 | 2853 | 5479 | 2632 |
| fields | 18999 | 10235 | 19089 | 8916 |

## Building

`src/` holds the generated sources, written by

```
./gen.py --structs 40 --units 24 --uses 15 src
```

The generator is seeded, so it rewrites the same files, but `src/` is the
reference. `./build.sh` then compiles them and runs dwz, twice:

| DWARF | compiler | dwz | override with |
|---|---|---|---|
| 4 | gcc 8.5.0 (Red Hat 8.5.0-18) | 0.12 | `CC4`, `DWZ4` |
| 5 | gcc 12.2.1 (gcc-toolset-12) | 0.14 | `CC5`, `DWZ5` |

dwz handles DWARF 5 from 0.14 on, so the DWARF 5 build needs a newer dwz than
RHEL 8 ships. `build.sh` lists the units in a fixed order, since their order
decides how dwz partitions the types, and maps the build directory to `.`
(`-ffile-prefix-map=$PWD=.`), so a rebuild anywhere with the same tools gives
the same bytes.
