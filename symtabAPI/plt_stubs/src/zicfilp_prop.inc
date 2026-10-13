	.section .note.gnu.property,"a",@note
	.p2align 3
	.long 4                   /* namesz: "GNU\0" */
	.long 16                  /* descsz: type + datasz + data + padding */
	.long 5                   /* NT_GNU_PROPERTY_TYPE_0 */
	.asciz "GNU"
	.p2align 3
	.long 0xc0000000          /* GNU_PROPERTY_RISCV_FEATURE_1_AND */
	.long 4
	.long 1                   /* CFI_LP_UNLABELED */
	.long 0
	.p2align 3
