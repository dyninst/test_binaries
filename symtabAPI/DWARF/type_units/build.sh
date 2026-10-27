#!/bin/sh
# Rebuild the binaries from src/ (see README.md):
#
#   DWARF 4  CC4/CXX4, by default gcc and g++ (8.5 on RHEL 8)
#   DWARF 5  CC5/CXX5, by default GCC 12 from gcc-toolset-12
#
# The build directory is mapped to ".", so that a rebuild anywhere with the
# same tools gives the same bytes.
set -e
cd "$(dirname "$0")"
CC4=${CC4:-gcc}
CXX4=${CXX4:-g++}
CC5=${CC5:-/opt/rh/gcc-toolset-12/root/usr/bin/gcc}
CXX5=${CXX5:-/opt/rh/gcc-toolset-12/root/usr/bin/g++}

FLAGS="-O0 -ffile-prefix-map=$PWD=. -gno-record-gcc-switches"
TU=-fdebug-types-section
CXX_SRC="src/shape.cpp src/main.cpp"
C_SRC="src/a.c src/b.c"

$CXX4 $FLAGS -gdwarf-4 $TU $CXX_SRC -o cxx_tu4
$CXX5 $FLAGS -gdwarf-5 $TU $CXX_SRC -o cxx_tu5
$CXX4 $FLAGS -gdwarf-4 $CXX_SRC -o cxx_plain4

$CC4 $FLAGS -gdwarf-4 $TU $C_SRC -o c_tu4
$CC5 $FLAGS -gdwarf-5 $TU $C_SRC -o c_tu5
$CC4 $FLAGS -gdwarf-4 $C_SRC -o c_plain4
