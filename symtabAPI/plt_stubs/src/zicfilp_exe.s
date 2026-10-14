	.text
	.globl _start
	.type _start, @function
_start:
	call foo
	call bar
	li a7, 93
	li a0, 0
	ecall
	.size _start, .-_start
	.data
	.globl ptr
ptr:	.dword extvar
	.include "zicfilp_prop.inc"
