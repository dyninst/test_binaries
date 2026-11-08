Split DWARF (`-gsplit-dwarf`): most of each unit's DWARF is in a separate
`.dwo` file, and the binary keeps a skeleton unit that names it.

DWARF 4 split DWARF is a GNU extension: the skeleton is a `DW_TAG_compile_unit`
with `DW_AT_GNU_dwo_name`. DWARF 5 standardized it: the skeleton is a
`DW_TAG_skeleton_unit` with `DW_AT_dwo_name`. In both, the variables,
parameters and types are only in the `.dwo` file, and libdw reads it when it
is next to the binary.

## The binaries

One program, `src/split.c`: a global `struct pair g_pair` (16 bytes) and
`int add(int x, int y)`.

| binary | compiler | DWARF | skeleton |
|---|---|---|---|
| `clang_dwarf5_split` | clang 15 | 5 | `DW_TAG_skeleton_unit` |
| `gcc_dwarf5_split` | GCC 12 | 5 | `DW_TAG_skeleton_unit` |
| `clang_dwarf4_split` | clang 15 | 4 | `DW_TAG_compile_unit` |
| `gcc_dwarf4_split` | GCC 8.5 | 4 | `DW_TAG_compile_unit` |
| `gcc_dwarf5` | GCC 12 | 5 | none (not split), the control |

Each `<binary>.dwo` belongs to the binary of the same name and must stay next
to it.

## Expected

What the control gives, and what every binary should give:

- a module for `src/split.c`, with line information (`main` at line 6);
- `g_pair`: `struct pair`, 16 bytes;
- `add`: parameters `x` and `y`, `int`.

## Building

`build.sh` rebuilds the binaries reproducibly with clang 15 and GCC 8.5 from
RHEL 8 and GCC 12 from gcc-toolset-12. No path of the build machine is
recorded.
