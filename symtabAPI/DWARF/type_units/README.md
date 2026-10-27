Variables whose types are defined in DWARF type units.

With `-fdebug-types-section` a compiler emits each type once, in a type unit
(`DW_TAG_type_unit`), and the units that use it refer to it by its 8-byte
signature (`DW_FORM_ref_sig8`), or through a memberless declaration carrying
`DW_AT_signature`. DWARF 4 keeps type units in `.debug_types`, DWARF 5 in
`.debug_info`. A reader that does not resolve the signatures to the type units
that define them gives these variables the wrong size, or no type at all.

## The binaries

Two programs, each built with type units for DWARF 4 and for DWARF 5, and
once without type units, whose types the others must match.

| binary | DWARF | type units |
|---|---|---|
| `cxx_tu4` | 4 | 181 |
| `cxx_tu5` | 5 | 197 |
| `cxx_plain4` | 4 | none |
| `c_tu4` | 4 | 2 |
| `c_tu5` | 5 | 2 |
| `c_plain4` | 4 | none |

- `cxx_*`, from `src/shape.cpp` and `src/main.cpp`: two units sharing, through
  `src/shapes.h`, a class `Shape` and the `std::map`, `std::shared_ptr` and
  `std::function` it uses. Its globals are `gshape`, `gmap`, `gptr`, `gfun`,
  and `gnode`, a `std::_Rb_tree_node_base`.
- `c_*`, from `src/a.c` and `src/b.c`: each unit defines its own
  `struct Shape`, a 4-byte one with one member in `a.c` (variable `ga`) and a
  24-byte one with three in `b.c` (variable `gb`). C allows two units to give
  different types the same tag, so the type units for the two must stay
  apart.

The type units were counted with `readelf --debug-dump=info`.

## Expected types

What the binaries without type units give, and so what every binary should
give:

| variable | size | fields |
|---|---|---|
| `gshape` | 120 | 8 |
| `gmap` | 48 | |
| `gptr` | 16 | |
| `gfun` | 32 | |
| `gnode` | 32 | 8 |
| `ga` | 4 | 1 |
| `gb` | 24 | 3 |

Fields are the components Dyninst reports for the type. They are checked only
where they do not depend on the C++ library: `std::map` has 56 with GCC 8.5's
libstdc++ and 60 with GCC 12's.

## Building

`build.sh` rebuilds the binaries reproducibly, at `-O0`, with gcc and g++ 8.5
for DWARF 4 and GCC 12 from gcc-toolset-12 for DWARF 5. The build directory is
mapped to `.`, so a rebuild anywhere with the same tools gives the same bytes.
