#!/bin/sh
# Rebuild this host's mutatees from the src/ directories (see README.md):
#
#   ./build.sh            on an aarch64 or ppc64le Linux host
#
# Each test directory has src/aarch64.c and src/ppc64le.c; the binary for the
# host's architecture is written next to src/ as aarch64 or ppc64le.  The
# binaries are executed by the tests, so build them against a glibc older than
# 2.34 (they then run on every newer one): the committed ones come from
# a RHEL 8 ppc64le host (glibc 2.28) and an Ubuntu 20.04 aarch64 host (glibc
# 2.31); README.md lists the compilers.  They are not stripped: the tests look up their
# labels with SymtabAPI.  The build directory is mapped to ".", so that a
# rebuild anywhere with the same tools gives the same bytes.
set -e
cd "$(dirname "$0")"
case "$(uname -m)" in
  aarch64) arch=aarch64 ;;
  ppc64le) arch=ppc64le ;;
  *) echo "build.sh: run this on an aarch64 or ppc64le host" >&2; exit 1 ;;
esac
CC=${CC:-gcc}
FLAGS="-O2 -g -std=c11 -fno-pie -no-pie -ffile-prefix-map=$PWD=. -gno-record-gcc-switches"

for dir in atomicSeqInnerBranch refusedStepAtBreakpoint stepOffDuringEmulatedStep; do
  $CC $FLAGS -o "$dir/$arch" "$dir/src/$arch.c"
done
