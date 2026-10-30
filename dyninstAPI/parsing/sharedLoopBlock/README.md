## Test binary for a loop head shared by two functions

Input of the dyninst test `dyninstAPI_sharedLoopBlock_test`
(dyninst/dyninst#2559). The test only parses the binary; it never runs it.

`loop_entrant` jumps into the loop of `loop_owner`, so the loop's head block
belongs to both functions:

```
loop_owner:    xor  eax, eax
  head:        add  eax, 1          <- in loop_owner and loop_entrant
               cmp  eax, edi
               jl   head
               ret
loop_entrant:  mov  eax, 1
               jmp  head            <- edge into head from a block not in loop_owner
```

In `loop_owner`'s flow graph the head has an incoming edge from a block that
only `loop_entrant` has. No instrumentation point can be made for that edge,
and `BPatch_edge::getPoint` must return NULL for it. The test finds the
functions by name, so the binary keeps its symbol table.

`x86_64` is built from `sharedLoopBlock.s` with

```
gcc -o x86_64 sharedLoopBlock.s
```

using GCC 8.5.0 and GNU assembler 2.30 on RHEL 8. Built twice, in two
different directories, the binary came out byte-identical.
