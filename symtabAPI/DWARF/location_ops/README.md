Optimized code: variables whose DWARF locations use operations beyond a fixed
address, a register or a frame offset.

At `-O2`, compilers describe many parameters and locals with location lists
whose entries use `DW_OP_entry_value`, `DW_OP_implicit_pointer`,
`DW_OP_implicit_value`, `DW_OP_convert` or `DW_OP_GNU_parameter_ref`. A reader
that can't evaluate one of these loses that part of the variable's location,
and the whole variable when it was the only part.

## The binaries

`src/location_ops.c` has one function per case, named for the operation it is
meant to produce (`entry_value`, `implicit_ptr`, `implicit_val`, `narrowed`,
`param_ref`). `src/param_ref.cpp` is a recursive member function that GCC
clones without `this` (`Tree::erase(Node*) [clone .isra.0]`).

| binary | compiler | DWARF | operations (counted with `eu-readelf`) |
|---|---|---|---|
| `clang_dwarf5` | clang 15 | 5 | `DW_OP_entry_value` 9, `DW_OP_convert` 4, `DW_OP_implicit_value` 2 |
| `clang_dwarf4` | clang 15 | 4 | `DW_OP_GNU_entry_value` 9, `DW_OP_implicit_value` 2 |
| `gcc_dwarf5` | GCC 12 | 5 | `DW_OP_entry_value` 4, `DW_OP_implicit_pointer` 1, `DW_OP_implicit_value` 2, `DW_OP_GNU_parameter_ref` 1 |
| `gcc_dwarf4` | GCC 8.5 | 4 | `DW_OP_GNU_entry_value` 5, `DW_OP_GNU_implicit_pointer` 1, `DW_OP_implicit_value` 2, `DW_OP_GNU_parameter_ref` 1 |
| `gxx_param_ref` | GCC 12 | 5 | `DW_OP_GNU_parameter_ref` 1 (for `this`), `DW_OP_entry_value` 3, `DW_OP_implicit_pointer` 2 |

clang emits `DW_OP_convert` only for DWARF 5: in `clang_dwarf4`, `narrowed`'s
`c` has a plain register location instead.

## Building

`build.sh` rebuilds the binaries reproducibly at `-O2` with clang 15 and GCC
8.5 from RHEL 8 and GCC 12 from gcc-toolset-12. No path of the build machine
is recorded.
