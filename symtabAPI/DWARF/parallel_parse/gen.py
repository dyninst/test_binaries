#!/usr/bin/env python3
"""Write shared.h and cu<N>.c: many compilation units that all use one set of
struct and union types, so that dwz moves the types into partial units that
every unit imports.

usage: gen.py <dir> <structs> <units> <uses per unit>
"""
import os
import random
import sys

out, nstructs, nunits, nuses = sys.argv[1], *map(int, sys.argv[2:5])
random.seed(2410)
os.makedirs(out, exist_ok=True)

h = ["#ifndef SHARED_H", "#define SHARED_H"]
for i in range(nstructs):
    fields = [f"  int i{i}_{k};" for k in range(3)]
    fields += [f"  double d{i};", f"  char name{i}[{8 + i % 5}];"]
    if i > 0:
        for j in random.sample(range(i), min(3, i)):
            fields.append(f"  struct s{j} m{j};")
        fields.append(f"  struct s{random.randrange(i)} *p{i};")
    h.append(f"struct s{i} {{\n" + "\n".join(fields) + "\n};")
    h.append(f"union u{i} {{ struct s{i} s; int raw[{2 + i % 3}]; }};")
h.append("#endif")
with open(os.path.join(out, "shared.h"), "w") as f:
    f.write("\n".join(h) + "\n")

for c in range(nunits):
    body = ['#include "shared.h"']
    for k, i in enumerate(random.sample(range(nstructs), nuses)):
        body.append(
            f"int cu{c}_f{k}(struct s{i} *a, union u{i} *b) {{ struct s{i} l = *a; "
            f"l.i{i}_0 += b->raw[0]; *a = l; return a->i{i}_1 + l.i{i}_2; }}"
        )
    with open(os.path.join(out, f"cu{c}.c"), "w") as f:
        f.write("\n".join(body) + "\n")
