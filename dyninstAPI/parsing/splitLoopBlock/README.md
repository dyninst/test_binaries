## Test binary for a loop block split by a function found later

Input of the dyninst test `dyninstAPI_splitLoopBlock_test`. The test only
parses the binary; it never runs it.

`loop_func` has a loop. A second function, which has no symbol, jumps into
the middle of that loop:

```
loop_func:     xor  eax, eax
               jmp  head
  head:        add  eax, 1
  mid:         add  eax, 2          <- target of the jump below
               cmp  eax, edi
               jl   head            <- back edge
               ret
(no symbol):   push rbp
               mov  rbp, rsp
               mov  eax, 1
               jmp  mid
```

Dyninst parses `loop_func` first, from its symbol, and finds the unnamed
function later by gap parsing. Its jump to `mid` splits `loop_func`'s loop
block in two, and `loop_func` keeps only the first half: the block from `mid`
to the back edge `jl head` is not in `loop_func`. The loop analysis still
reports that back edge for `loop_func`'s loop, and no instrumentation point
can be made for it in `loop_func`.

The same happens in RHEL 8's `libcrypto.so.1.1.1k` (openssl-libs
1.1.1k-9.el8_7) at 0x86290, in AES-NI code that jumps into the middle of a
loop.

`x86_64` is built from `splitLoopBlock.s` with

```
gcc -o x86_64 splitLoopBlock.s
```

using GCC 8.5.0 and GNU assembler 2.30 on RHEL 8. Built twice, in two
different directories, the binary came out byte-identical.
