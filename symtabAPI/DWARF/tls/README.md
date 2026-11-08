Thread-local variables (`_Thread_local`, `__thread`).

A thread-local variable's location is its offset in the module's TLS block,
followed by an operation that turns it into an address in the current
thread: `DW_OP_GNU_push_tls_address` (GCC with DWARF 4, clang with both) or
`DW_OP_form_tls_address` (GCC with DWARF 5).

## The binaries

One program, `src/tls.c`: thread-local `int t_int` and `long t_long`, and an
ordinary global `int g_int` for comparison.

| binary | compiler | DWARF | `t_int`'s location |
|---|---|---|---|
| `clang_dwarf5` | clang 15 | 5 | `DW_OP_const8u 0, DW_OP_GNU_push_tls_address` |
| `clang_dwarf4` | clang 15 | 4 | `DW_OP_const8u 0, DW_OP_GNU_push_tls_address` |
| `gcc_dwarf5` | GCC 12 | 5 | `DW_OP_const8u 0, DW_OP_form_tls_address` |
| `gcc_dwarf4` | GCC 8.5 | 4 | `DW_OP_const8u 0, DW_OP_GNU_push_tls_address` |

In `clang_dwarf5`, `g_int`'s location is `DW_OP_addrx` (see `../global_vars`).

## Expected

`t_int`: `int`, 4 bytes; `t_long`: `long`, 8 bytes; `g_int`: `int`, 4 bytes.

## Building

`build.sh` rebuilds the binaries reproducibly at `-O0` with clang 15 and GCC
8.5 from RHEL 8 and GCC 12 from gcc-toolset-12. No path of the build machine
is recorded.
