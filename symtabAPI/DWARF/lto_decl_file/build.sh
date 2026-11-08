#!/bin/sh
# Rebuild the binaries from src/ (see README.md), at -O2, with
#
#   GCC4  by default gcc 8.5 (/usr/bin/gcc on RHEL 8), for DWARF 4
#   GCC5  by default GCC 12 from gcc-toolset-12, for DWARF 5
#
# No path of the build machine is recorded.
set -e
cd "$(dirname "$0")"
GCC4=${GCC4:-/usr/bin/gcc}
GCC5=${GCC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
MAP="-ffile-prefix-map=$PWD=."
GNO=-gno-record-gcc-switches

$GCC5 -O2 -flto -gdwarf-5 $MAP $GNO src/a.c src/b.c -o gcc_lto_dwarf5
$GCC4 -O2 -flto -gdwarf-4 $MAP $GNO src/a.c src/b.c -o gcc_lto_dwarf4
$GCC5 -O2 -gdwarf-5 $MAP $GNO src/a.c src/b.c -o gcc_dwarf5
