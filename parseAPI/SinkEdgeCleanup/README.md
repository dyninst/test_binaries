A bogus jump-table target whose block ends with a sink edge (x86_64, PIC shared object).

`fa` reads its table `TA` with an index it never bounds, so ParseAPI reads past `TA` into
`TB`. `TB`'s first entry, taken relative to `TA`, lands 16 bytes before `fb`'s first case,
on dead bytes after `fb`'s indirect jump: a `nop` and a `jmp` to an address outside the
code, which ParseAPI links to the sink. `fb`'s own switch is bounded, so `TB` is a known
table start and `finalize_jump_tables` cuts `fa`'s table at `TB` and deletes the overrun
edges; the bogus block is then reachable from nothing and its sink edge is deleted too.

A correct parse leaves no edge in the sink block's sources that is missing from its source
block's targets.

See the source for the layout. Built with

```console
$ gcc -shared -nostdlib -Wl,--build-id=none -o jt_sink.so jt_sink.s   # gcc 15.2.0 (spack), GNU as 2.30, Rocky Linux 8.8 x86_64
```
