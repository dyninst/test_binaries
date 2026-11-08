Global variables whose locations are given as DWARF 5 address indices.

DWARF 5 lets a producer move the addresses in location expressions into
`.debug_addr`: a global's `DW_AT_location` is then `DW_OP_addrx <index>`
instead of `DW_OP_addr <address>`. clang does this for every DWARF 5 global;
GCC does it only with `-gsplit-dwarf`. A reader that doesn't resolve the index
can't match the variable to its symbol, and the variable keeps no type.

## The binaries

One program, `src/global_vars.c`, built five ways at `-O0`:

| binary | compiler | DWARF | locations | `DW_AT_decl_file` 0 |
|---|---|---|---|---|
| `clang_dwarf5` | clang 15 | 5 | `DW_OP_addrx` | no |
| `clang_dwarf5_relpath` | clang 15 | 5 | `DW_OP_addrx` | yes (18 DIEs) |
| `clang_dwarf4` | clang 15 | 4 | `DW_OP_addr` | no |
| `gcc_dwarf5` | GCC 12 | 5 | `DW_OP_addr` | no |
| `gcc_dwarf4` | GCC 8.5 | 4 | `DW_OP_addr` | no |

`clang_dwarf5_relpath` is built from a relative path, so its primary source
file is file 0 of the line table, and the DIEs declared in it have
`DW_AT_decl_file` 0. DWARF 5 allows 0; a reader that treats it as "no file"
drops those variables too (dyninst#2421). The binaries with `DW_OP_addr`
locations are the controls.

The locations and file numbers were counted with `eu-readelf --debug-dump=info`.

## Expected types

| variable | type | size | fields |
|---|---|---|---|
| `g_i8` | `int8_t` | 1 | |
| `g_i16` | `int16_t` | 2 | |
| `g_i32` | `int32_t` | 4 | |
| `g_i64` | `int64_t` | 8 | |
| `g_vlong` | `volatile long` | 8 | |
| `g_pair` | `struct pair` | 16 | 2 |
| `g_array` | `int32_t[10]` | 40 | |
| `g_bss` | `int64_t`, in `.bss` | 8 | |
| `g_static` | `static int32_t` | 4 | |

`counter()` also has a function-scope `static int calls`, whose location is
`DW_OP_addrx` in the clang DWARF 5 binaries too. `twice(int value)` has a
parameter and a local, `doubled`, on the stack (`DW_OP_fbreg`): in
`clang_dwarf5_relpath` they have `DW_AT_decl_file` 0, independently of
`DW_OP_addrx`.

## Building

`build.sh` rebuilds the binaries reproducibly with clang 15 and GCC 8.5 from
RHEL 8 and GCC 12 from gcc-toolset-12. No path of the build machine is
recorded, so a rebuild anywhere with the same tools gives the same bytes.
