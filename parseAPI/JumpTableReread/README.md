A jump table that is read twice with different extents (x86_64, PIC shared object).

`fa` reads its table `TA` with an index it never bounds, so ParseAPI reads up to 256
entries and runs past `TA` into `TB`. `TB`'s first entry, taken relative to `TA`, lands
exactly on `fb`'s dispatch `lea`, so `fa`'s frame parses `fb`'s dispatch block as its own
and analyzes `fb`'s jump (at `0x724`) without `fb`'s `and $3` from the block before: no
bound, and the read runs from `TB` into `TC` (2 extra targets in `fc`). `fa` and `g` call
each other and `fa` has no `ret`, so `fa`'s frame stays open until that cycle is broken,
after `fb` has been parsed; the value-driven re-read of `fb`'s jump then sees the
`and $3` and reads only `TB`'s 4 entries. `fc`'s switch makes `TC` a known table start.

A correct parse leaves `fb`'s jump with exactly its 4 targets in `fb`. If the jump-table
record keeps only the latest read, `finalize_jump_tables` cannot trim the 2 targets in
`fc`. The frame order this needs (`g`, `fa`, then `fb`, by descending hint gap) holds in a
serial parse (`OMP_NUM_THREADS=1`).

See the source for the layout. Built with

```console
$ gcc -shared -nostdlib -Wl,--build-id=none -o jt_reread.so jt_reread.s   # gcc 15.2.0 (spack), GNU as 2.30, Rocky Linux 8.8 x86_64
```
