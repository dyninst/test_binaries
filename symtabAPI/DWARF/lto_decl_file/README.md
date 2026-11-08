Link-time optimization: DIEs whose `DW_AT_decl_file` belongs to another
unit's file table.

With `-flto`, GCC emits the source-level description of each translation unit
at compile time ("early debug"), and the code generated at link time gets its
own unit (named `<artificial>`) whose DIEs point back to the early ones with
`DW_AT_abstract_origin`. An attribute such as `DW_AT_decl_file` that is taken
from the abstract origin is an index into the file table of the origin's
unit, not of the unit the concrete DIE is in.

## The binaries

Two files: `src/a.c` calls `scale(int32_t value, size_t factor)` from
`src/b.c`, which has a function-scope `static int calls`. `b.c` includes
several headers, so its file table is longer than that of the link-time unit.

| binary | compiler | DWARF | LTO |
|---|---|---|---|
| `gcc_lto_dwarf5` | GCC 12 | 5 | yes |
| `gcc_lto_dwarf4` | GCC 8.5 | 4 | yes |
| `gcc_dwarf5` | GCC 12 | 5 | no, the control |

## Expected

`scale`: parameters `value` (`int32_t`, 4 bytes) and `factor` (`size_t`, 8
bytes), and a local `calls` (`int`).

## Building

`build.sh` rebuilds the binaries reproducibly at `-O2` with GCC 8.5 from
RHEL 8 and GCC 12 from gcc-toolset-12. No path of the build machine is
recorded.
