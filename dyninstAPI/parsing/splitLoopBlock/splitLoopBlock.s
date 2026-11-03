# loop_func has a loop. A second function, with no symbol, jumps into the
# middle of that loop at .Lmid. Dyninst parses loop_func first, from its
# symbol, and finds the unnamed function later by gap parsing; the jump to
# .Lmid then splits loop_func's loop block in two.

  .text

  .globl loop_func
  .type loop_func, @function
loop_func:
  xorl %eax, %eax
  jmp .Lhead
  .p2align 4
.Lhead:
  addl $1, %eax
.Lmid:
  addl $2, %eax
  cmpl %edi, %eax
  jl .Lhead
  ret
  .size loop_func, .-loop_func

  .p2align 4
.Lunnamed:
  pushq %rbp
  movq %rsp, %rbp
  movl $1, %eax
  jmp .Lmid

  .p2align 4
  .globl main
  .type main, @function
main:
  call loop_func
  ret
  .size main, .-main

  .section .note.GNU-stack,"",@progbits
