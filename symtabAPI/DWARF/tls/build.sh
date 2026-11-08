#!/bin/sh
# Rebuild the binaries from src/ (see README.md), at -O0, with
#
#   CLANG  by default clang 15 (/usr/bin/clang-15 on RHEL 8)
#   GCC4   by default gcc 8.5 (/usr/bin/gcc on RHEL 8), for DWARF 4
#   GCC5   by default GCC 12 from gcc-toolset-12, for DWARF 5
#
# No path of the build machine is recorded.
set -e
cd "$(dirname "$0")"
CLANG=${CLANG:-/usr/bin/clang-15}
GCC4=${GCC4:-/usr/bin/gcc}
GCC5=${GCC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
MAP="-fdebug-prefix-map=$PWD=."
GNO=-gno-record-gcc-switches

# clang names the source by an absolute path (mapped to /build), so that
# DW_AT_decl_file is never 0 (dyninst#2421).
$CLANG -O0 -gdwarf-5 -fdebug-prefix-map="$PWD=/build" "$PWD/src/tls.c" -o clang_dwarf5
$CLANG -O0 -gdwarf-4 -fdebug-prefix-map="$PWD=/build" "$PWD/src/tls.c" -o clang_dwarf4
$GCC5 -O0 -gdwarf-5 $MAP $GNO src/tls.c -o gcc_dwarf5
$GCC4 -O0 -gdwarf-4 $MAP $GNO src/tls.c -o gcc_dwarf4
