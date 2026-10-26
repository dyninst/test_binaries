#!/bin/sh
# Rebuild the binaries from src/ (see README.md), each layout twice:
#
#   DWARF 4  CC4 and DWZ4, by default gcc and dwz (gcc 8.5 and dwz 0.12 on
#            RHEL 8)
#   DWARF 5  CC5 and DWZ5, by default GCC 12 from gcc-toolset-12 and dwz;
#            dwz handles DWARF 5 from 0.14 on
#
# The units are listed in a fixed order, since their order decides how dwz
# partitions the types, and the build directory is mapped to ".", so that a
# rebuild anywhere with the same tools gives the same bytes.
set -e
cd "$(dirname "$0")"
CC4=${CC4:-gcc}
DWZ4=${DWZ4:-dwz}
CC5=${CC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
DWZ5=${DWZ5:-dwz}

units() { seq "$1" "$2" | sed 's|.*|src/cu&.c|'; }
ALL=$(units 0 23)
A=$(units 0 11)
B=$(units 12 23)
FLAGS="-O2 -fPIC -shared -ffile-prefix-map=$PWD=. -gno-record-gcc-switches"

# build <cc> <dwz> <dwarf version> <suffix>
build() {
  # Single-file dwz: shared types in partial units inside the library.
  $1 $FLAGS -gdwarf-$3 $ALL -o shared_types_dwz$4.so
  $2 shared_types_dwz$4.so

  # Multi-file dwz: two libraries, each with half the units, whose shared
  # types move into the supplementary file shared_types$4.dwz.
  $1 $FLAGS -gdwarf-$3 $A -o shared_types_alt$4_a.so
  $1 $FLAGS -gdwarf-$3 $B -o shared_types_alt$4_b.so
  $2 -m shared_types$4.dwz -M shared_types$4.dwz \
    shared_types_alt$4_a.so shared_types_alt$4_b.so
}

build "$CC4" "$DWZ4" 4 ""
build "$CC5" "$DWZ5" 5 5
