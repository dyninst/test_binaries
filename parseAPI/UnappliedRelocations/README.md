Parse an unlinked object file (`ET_REL`) whose direct calls and branches carry
unapplied relocations. The displacement bytes of such instructions are
placeholders, so the decoded target is meaningless (typically the next
instruction, or one past the end of the section) and must not be treated as a
concrete control-flow target.

See [dyninst#2352](https://github.com/dyninst/dyninst/pull/2352) for details.

`loadmsgcat.o` is the unmodified member of glibc's static `libc.a`
(`glibc-static-2.28-225.el8_8.6.x86_64`, Rocky Linux 8.8), extracted with

```console
$ ar x /usr/lib64/libc.a loadmsgcat.o
```

Its section `__libc_freeres_fn` spans `[0, 0xe5)` and ends with an unrelocated
tail call to `free`:

```console
$ objdump -dr --section=__libc_freeres_fn loadmsgcat.o | tail -3
  e0:   e9 00 00 00 00    jmpq   e5 <.annobin__nl_unload_domain.end>
                          e1: R_X86_64_PLT32     free-0x4
```

Every section in a `.o` is based at 0, so the placeholder target `0xe5` falls
inside the overlapping `.text` section and the jump used to be parsed as a
cross-region tail call, which could crash the parser. With
`DYNINST_DEBUG_PARSING=1` a fixed ParseAPI instead reports

```
REJECTED: CF target of 'jmp 0x5(%rip)' at 0xe0 carries an unapplied relocation (placeholder target 0xe5)
```
