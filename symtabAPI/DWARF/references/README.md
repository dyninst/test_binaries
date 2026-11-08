C++ reference parameters.

A reference is passed as a pointer, so its size is the address size. GCC
gives `DW_TAG_reference_type` a `DW_AT_byte_size` of 8 on x86_64; clang gives
none, which means the address size.

## The binaries

One program, `src/references.cpp`:
`int by_ref(int &r, const double &d, int *p)` (`_Z6by_refRiRKdPi`).

| binary | compiler | DWARF | reference `DW_AT_byte_size` |
|---|---|---|---|
| `gcc_dwarf5` | G++ 12 | 5 | 8 |
| `gcc_dwarf4` | G++ 8.5 | 4 | 8 |
| `clang_dwarf5` | clang 15 | 5 | none |

## Expected

`r` and `d`: references, 8 bytes, to `int` and `const double`; `p`: `int *`,
8 bytes.

## Building

`build.sh` rebuilds the binaries reproducibly at `-O0` with clang 15 and G++
8.5 from RHEL 8 and G++ 12 from gcc-toolset-12. No path of the build machine
is recorded.
