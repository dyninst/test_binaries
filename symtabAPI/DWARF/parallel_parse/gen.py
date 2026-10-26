#!/usr/bin/env python3
"""Write shared.h and cu<N>.c: many compilation units that all use one set of
struct and union types, so that dwz moves the types into partial units that
every unit imports.

    ./gen.py --structs 40 --units 24 --uses 15 src

writes the sources in src/.
"""
import argparse
import os
import random

ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
ap.add_argument("--structs", type=int, required=True,
                help="number of structs in shared.h, each with a union around it")
ap.add_argument("--units", type=int, required=True, help="number of cu<N>.c files")
ap.add_argument("--uses", type=int, required=True,
                help="how many of the structs each unit uses, picked at random")
ap.add_argument("dir", help="directory to write the sources in")
args = ap.parse_args()

# A fixed seed, so the same arguments always write the same files.  Its value
# is arbitrary; 2410 is the dyninst issue the binaries were first built for.
random.seed(2410)
os.makedirs(args.dir, exist_ok=True)

h = ["#ifndef SHARED_H", "#define SHARED_H"]
for i in range(args.structs):
    fields = [f"  int i{i}_{k};" for k in range(3)]
    fields += [f"  double d{i};", f"  char name{i}[{8 + i % 5}];"]
    if i > 0:
        for j in random.sample(range(i), min(3, i)):
            fields.append(f"  struct s{j} m{j};")
        fields.append(f"  struct s{random.randrange(i)} *p{i};")
    h.append(f"struct s{i} {{\n" + "\n".join(fields) + "\n};")
    h.append(f"union u{i} {{ struct s{i} s; int raw[{2 + i % 3}]; }};")
h.append("#endif")
with open(os.path.join(args.dir, "shared.h"), "w") as f:
    f.write("\n".join(h) + "\n")

for c in range(args.units):
    body = ['#include "shared.h"']
    for k, i in enumerate(random.sample(range(args.structs), args.uses)):
        body.append(
            f"int cu{c}_f{k}(struct s{i} *a, union u{i} *b) {{ struct s{i} l = *a; "
            f"l.i{i}_0 += b->raw[0]; *a = l; return a->i{i}_1 + l.i{i}_2; }}"
        )
    with open(os.path.join(args.dir, f"cu{c}.c"), "w") as f:
        f.write("\n".join(body) + "\n")
