# loop_entrant jumps into the loop of loop_owner, so the loop's head block
# belongs to both functions. In loop_owner's flow graph the head has an
# incoming edge from a block that only loop_entrant has.

  .text
  .globl loop_owner
  .type loop_owner, @function
loop_owner:
  xorl %eax, %eax
.Lloop_head:
  addl $1, %eax
  cmpl %edi, %eax
  jl .Lloop_head
  ret
  .size loop_owner, .-loop_owner

  .globl loop_entrant
  .type loop_entrant, @function
loop_entrant:
  movl $1, %eax
  jmp .Lloop_head
  .size loop_entrant, .-loop_entrant

  .globl main
  .type main, @function
main:
  pushq %rbx
  movl %edi, %ebx
  call loop_owner
  movl %eax, %ecx
  movl %ebx, %edi
  pushq %rcx
  call loop_entrant
  popq %rcx
  addl %ecx, %eax
  popq %rbx
  ret
  .size main, .-main

  .section .note.GNU-stack,"",@progbits
