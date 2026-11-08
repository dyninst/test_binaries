#!/bin/sh
# Rebuild the binaries from src/ (see README.md) with GCC 12 from
# gcc-toolset-12 (GCC5), at -O0. No path of the build machine is recorded.
set -e
cd "$(dirname "$0")"
GCC5=${GCC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}

# With DWARF: Dyninst knows each global's type and size.
$GCC5 -O0 -g -ffile-prefix-map="$PWD=." -gno-record-gcc-switches src/store_width.c -o store_width_g
# Without: Dyninst finds the globals only through their ELF symbols.
$GCC5 -O0 -ffile-prefix-map="$PWD=." src/store_width.c -o store_width_nodebug
