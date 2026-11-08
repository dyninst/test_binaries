#!/bin/sh
# Rebuild the binaries from src/ (see README.md), at -O2, with
#
#   CLANG  by default clang 15 (/usr/bin/clang-15 on RHEL 8)
#   GCC4   by default gcc 8.5 (/usr/bin/gcc on RHEL 8), for DWARF 4
#   GCC5   by default GCC 12 from gcc-toolset-12, for DWARF 5
#
# No path of the build machine is recorded, so that a rebuild anywhere with the
# same tools gives the same bytes.
set -e
cd "$(dirname "$0")"
CLANG=${CLANG:-/usr/bin/clang-15}
GCC4=${GCC4:-/usr/bin/gcc}
GCC5=${GCC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
GXX5=${GXX5:-/opt/rh/gcc-toolset-12/root/usr/bin/g++}
MAP="-fdebug-prefix-map=$PWD=."
GNO=-gno-record-gcc-switches

$CLANG -O2 -gdwarf-5 $MAP src/location_ops.c -o clang_dwarf5
$CLANG -O2 -gdwarf-4 $MAP src/location_ops.c -o clang_dwarf4
$GCC5 -O2 -gdwarf-5 $MAP $GNO src/location_ops.c -o gcc_dwarf5
$GCC4 -O2 -gdwarf-4 $MAP $GNO src/location_ops.c -o gcc_dwarf4
$GXX5 -O2 -gdwarf-5 $MAP $GNO src/param_ref.cpp -o gxx_param_ref
