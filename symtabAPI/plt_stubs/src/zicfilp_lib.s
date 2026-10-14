	.text
	.globl foo
	.type foo, @function
foo:
	ret
	.size foo, .-foo
	.globl bar
	.type bar, @function
bar:
	ret
	.size bar, .-bar
	.data
	.globl extvar
	.type extvar, @object
	.size extvar, 8
extvar:	.dword 42
	.include "zicfilp_prop.inc"
