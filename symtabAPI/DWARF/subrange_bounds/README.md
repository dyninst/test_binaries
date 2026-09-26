Array subranges whose bounds are only known at run time.

DWARF 5 section 5.13 allows `DW_AT_lower_bound`, `DW_AT_upper_bound`, and
`DW_AT_count` to be a constant, an expression (`exprloc`, or `block` before
DWARF 4), or a reference to a DIE holding the value. Only the constant forms
can be evaluated statically; the others describe runtime values. These binaries
cover every non-constant form that current compilers emit, next to
constant-bound control arrays in the same compilation unit.

| binary                    | built with                   | runtime-bound forms                  |
|---------------------------|------------------------------|--------------------------------------|
| `vla_gcc_O0`              | `gcc -g -O0 vla.c`           | `DW_AT_upper_bound` exprloc          |
| `vla_gcc_O2`              | `gcc -g -O2 vla.c`           | `DW_AT_upper_bound` ref4             |
| `vla_clang_O0`            | `clang -g -O0 vla.c`         | `DW_AT_count` ref4                   |
| `fortran_gfortran_O0`     | `gfortran -g -O0 bounds.f90` | lower/upper exprloc, lower/upper ref4 |
| `fortran_gfortran_dwarf3` | `gfortran -g -gdwarf-3 -O0 bounds.f90` | lower/upper block1, lower/upper ref4 |
| `fortran_flang_O0`        | `flang-new -g -O0 bounds.f90` (ROCm 7.0.2) | lower bound exprloc and ref4; `DW_AT_count` exprloc and ref4; constant `DW_AT_count` with the default lower bound omitted |
| `const_ref_clang_O1`      | `clang -g -O1 const_ref.c`   | `DW_AT_count` ref4 to a DIE with `DW_AT_const_value` (a constant, not a runtime bound) |
| `const_ref_gcc_O1`        | `gcc -g -O1 const_ref.c`     | `DW_AT_upper_bound` exprloc that is a single constant operation (`DW_OP_lit6`, `DW_OP_const2u`) |
| `fortran_gfortran_relname` | `gfortran -g -O0 bounds.f90`, relative source name | as `fortran_gfortran_O0`; the unit's `DW_AT_name` is relative, so the Fortran default lower bound must come from the unit's `DW_AT_language` |

The gcc/gfortran binaries were compiled (`-c`) with gcc 15.2.0 and linked with
the system gcc 8.5 driver (libgfortran linked dynamically), so no RPATH is
recorded; the clang ones were built with clang 20 (ROCm 7.0.2). All use
`-ffile-prefix-map=<source dir>=/src`, the GNU ones also
`-gno-record-gcc-switches`. Every source path is absolute except in
`fortran_gfortran_relname`. The Fortran sources were compiled from `/mnt`
(a bind mount of this directory), because gfortran writes the source path it
opens into its runtime error messages and ignores the prefix map there.
`fortran_flang_O0` was also compiled from `/mnt`, which is the path it records:
flang-new has no prefix-map option. It links the flang runtime statically
(ROCm ships it only as `libFortranRuntime.a`), hence its size (about 860 KB).

Expected bounds (`?` = runtime, i.e. unknown; `*` = not checked):

`vla.c` (C, default lower bound 0)

| function | variable | bounds             |
|----------|----------|--------------------|
| `vla_1d` | `a`      | `[0:?]`            |
| `vla_2d` | `b`      | `[0:?][0:?]`       |
| `fixed`  | `c`      | `[0:9]`            |
| `fixed`  | `d`      | `[0:2][0:3]`       |

`bounds.f90` built with flang (Fortran, default lower bound 1). LLVM omits
`DW_AT_lower_bound` when it equals the language default and describes the
extent with `DW_AT_count`, so `u(10)` is `DW_AT_count 10` with no lower bound.

| function                     | variable | bounds  |
|------------------------------|----------|---------|
| `_QQmain`                    | `z`      | `[*:?]` (runtime lower bound) |
| `_QMshapesPassumed_shape`    | `x`      | `[1:?]` |
| `_QMshapesPexplicit_dyn`     | `y`      | `[*:?]` (runtime lower bound) |
| `_QMshapesPassumed_size`     | `v`      | `[1:?]` |
| `_QMshapesPfixed`            | `w`      | `[3:7]` |
| `_QMshapesPfixed`            | `u`      | `[1:10]` |

`const_ref.c` (C; both binaries describe constants: clang through a reference
to `DW_AT_const_value`, gcc as a single constant operation)

| function        | variable | bounds    |
|-----------------|----------|-----------|
| `const_vla`     | `a`      | `[0:6]`   |
| `const_vla_300` | `b`      | `[0:299]` |

`bounds.f90` (Fortran, default lower bound 1)

| function                     | variable | shape             | bounds  |
|------------------------------|----------|-------------------|---------|
| `MAIN__`                     | `z`      | allocatable       | `[*:?]` (runtime lower bound) |
| `__shapes_MOD_assumed_shape` | `x`      | assumed-shape `(:)` | `[1:?]` (lower bound omitted by gfortran) |
| `__shapes_MOD_explicit_dyn`  | `y`      | `(lo:hi)`         | `[*:?]` (runtime lower bound) |
| `__shapes_MOD_assumed_size`  | `v`      | assumed-size `(*)` | `[1:?]` (no upper bound attribute) |
| `__shapes_MOD_fixed`         | `w`      | `(3:7)`           | `[3:7]` |
| `__shapes_MOD_fixed`         | `u`      | `(10)`            | `[1:10]` |

A runtime lower bound is not checked: DWARF gives the language default only
to a subrange without `DW_AT_lower_bound`, and what to report for one whose
value is only known at run time is still an open question.
