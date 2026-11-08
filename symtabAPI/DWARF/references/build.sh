#!/bin/sh
# Rebuild the binaries from src/ (see README.md), at -O0, with
#
#   CLANGXX  by default clang 15 (/usr/bin/clang++-15 on RHEL 8)
#   GXX4     by default g++ 8.5 (/usr/bin/g++ on RHEL 8), for DWARF 4
#   GXX5     by default G++ 12 from gcc-toolset-12, for DWARF 5
#
# No path of the build machine is recorded.
set -e
cd "$(dirname "$0")"
CLANGXX=${CLANGXX:-/usr/bin/clang++-15}
GXX4=${GXX4:-/usr/bin/g++}
GXX5=${GXX5:-/opt/rh/gcc-toolset-12/root/usr/bin/g++}
MAP="-fdebug-prefix-map=$PWD=."
GNO=-gno-record-gcc-switches

$GXX5 -O0 -gdwarf-5 $MAP $GNO src/references.cpp -o gcc_dwarf5
$GXX4 -O0 -gdwarf-4 $MAP $GNO src/references.cpp -o gcc_dwarf4
# clang names the source by an absolute path (mapped to /build), so that
# DW_AT_decl_file is never 0 (dyninst#2421).
$CLANGXX -O0 -gdwarf-5 -fdebug-prefix-map="$PWD=/build" "$PWD/src/references.cpp" -o clang_dwarf5
