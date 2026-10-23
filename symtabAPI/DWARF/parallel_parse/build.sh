#!/bin/sh
# Rebuild the binaries from src/ (see README.md).
set -e
cd "$(dirname "$0")"
CFLAGS="-O2 -g -fPIC -shared -ffile-prefix-map=$PWD/src=/src -gno-record-gcc-switches"

# Single-file dwz: shared types in partial units inside the library.
gcc $CFLAGS src/cu*.c -o shared_types_dwz.so
dwz shared_types_dwz.so

# Multi-file dwz: two libraries, each with half the units, whose shared types
# move into the supplementary file shared_types.dwz.
gcc $CFLAGS src/cu[0-9].c src/cu1[01].c -o shared_types_alt_a.so
gcc $CFLAGS src/cu1[2-9].c src/cu2[0-3].c -o shared_types_alt_b.so
dwz -m shared_types.dwz -M shared_types.dwz shared_types_alt_a.so shared_types_alt_b.so
