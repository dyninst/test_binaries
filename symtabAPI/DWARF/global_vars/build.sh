#!/bin/sh
# Rebuild the binaries from src/ (see README.md), with
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

SRC=src/global_vars.c

# clang names the primary source file as it is given. Given by an absolute
# path, here mapped to /build, it is not file 0 of the line table, and only
# the DW_OP_addrx locations are new.
$CLANG -O0 -gdwarf-5 -fdebug-prefix-map="$PWD=/build" "$PWD/$SRC" -o clang_dwarf5
# Given by a relative path, it is file 0, so the variables' DW_AT_decl_file
# is 0, which DWARF 5 allows (#2421).
$CLANG -O0 -gdwarf-5 -fdebug-compilation-dir=. $SRC -o clang_dwarf5_relpath
$CLANG -O0 -gdwarf-4 -fdebug-prefix-map="$PWD=/build" "$PWD/$SRC" -o clang_dwarf4

$GCC5 -O0 -gdwarf-5 -ffile-prefix-map="$PWD=." -gno-record-gcc-switches $SRC -o gcc_dwarf5
$GCC4 -O0 -gdwarf-4 -ffile-prefix-map="$PWD=." -gno-record-gcc-switches $SRC -o gcc_dwarf4
