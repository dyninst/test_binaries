Stores into 1-, 2- and 8-byte globals, each followed by a neighbour.

`src/store_width.c` prints `g_char`, the three bytes after it
(`g_char_next`), `g_short`, the `short` after it (`g_short_next`) and
`g_long`. A mutator that stores into `g_char`, `g_short` and `g_long` shows in
the output how many bytes each store wrote, and whether it wrote the right
value.

Unmodified output:

```
g_char=1 next=2,3,4 g_short=5 next=6 g_long=0xffffffffffffffff
```

## The binaries

| binary | built | what Dyninst knows about the globals |
|---|---|---|
| `store_width_g` | GCC 12, `-O0 -g` | type and size from DWARF (1, 2 and 8 bytes) |
| `store_width_nodebug` | GCC 12, `-O0` | only the ELF symbols; no type |

## A mutator

Rewriting the binary so that `main` first assigns to each variable
(`BPatch_binaryEdit`, a snippet at `main`'s entry):

```cpp
for (char const *name : {"g_char", "g_short", "g_long"}) {
  BPatch_variableExpr *v = image->findVariable(name);
  // a constant:
  stores.push_back(new BPatch_arithExpr(BPatch_assign, *v, BPatch_constExpr(0)));
  // or a computed value:
  //   new BPatch_arithExpr(BPatch_assign, *v, BPatch_arithExpr(BPatch_minus, *v, *v))
}
app->insertSnippet(BPatch_sequence(stores), *main_entry);
app->writeFile(out);
```

Either way the expected output is

```
g_char=0 next=2,3,4 g_short=0 next=6 g_long=0
```

## Building

`build.sh` rebuilds the binaries reproducibly with GCC 12 from
gcc-toolset-12. No path of the build machine is recorded.
