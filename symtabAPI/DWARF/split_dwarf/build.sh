#!/bin/sh
# Rebuild the binaries from src/ (see README.md), with
#
#   CLANG  by default clang 15 (/usr/bin/clang-15 on RHEL 8)
#   GCC4   by default gcc 8.5 (/usr/bin/gcc on RHEL 8), for DWARF 4
#   GCC5   by default GCC 12 from gcc-toolset-12, for DWARF 5
#
# Each binary is compiled and linked in two steps, so its split DWARF goes to
# <binary>.dwo, next to it. No path of the build machine is recorded.
set -e
cd "$(dirname "$0")"
CLANG=${CLANG:-/usr/bin/clang-15}
GCC4=${GCC4:-/usr/bin/gcc}
GCC5=${GCC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
MAP="-fdebug-prefix-map=$PWD=."

build() { # <compiler> <flags> <source> <name>
  $1 $2 -O0 -c $3 -o $4.o
  $1 $4.o -o $4
  rm -f $4.o
}

# clang names the source by an absolute path (mapped to /build), so that
# DW_AT_decl_file is never 0 (dyninst#2421).
CLANG_SRC="-fdebug-prefix-map=$PWD=/build $PWD/src/split.c"
build $CLANG "-gdwarf-5 -gsplit-dwarf" "$CLANG_SRC" clang_dwarf5_split
build $GCC5 "-gdwarf-5 -gsplit-dwarf -gno-record-gcc-switches $MAP" src/split.c gcc_dwarf5_split
build $CLANG "-gdwarf-4 -gsplit-dwarf" "$CLANG_SRC" clang_dwarf4_split
build $GCC4 "-gdwarf-4 -gsplit-dwarf -gno-record-gcc-switches $MAP" src/split.c gcc_dwarf4_split
build $GCC5 "-gdwarf-5 -gno-record-gcc-switches $MAP" src/split.c gcc_dwarf5
