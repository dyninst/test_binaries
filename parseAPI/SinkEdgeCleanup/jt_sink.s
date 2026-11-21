# jt_sink.s: a bogus jump-table target whose block ends in a sink edge (x86_64, PIC).
#
#   fa reads its table TA with an index it never bounds, so the parser reads past TA's 4
#   entries into TB.  TB's first entry, taken relative to TA, lands 16 bytes before fb's
#   first case (.Lbogus = .Lfb_c0 - 16 = .Lfb_c0 - (TB - TA)), on dead bytes after fb's
#   indirect jump: a nop and a jmp to an address outside the code, which the parser links to
#   the sink.  fb's own switch is bounded, so TB is a known table start, and
#   finalize_jump_tables cuts fa's table at TB and deletes the overrun edges.  The block at
#   .Lbogus is then reachable from nothing, so the deletion continues into its sink edge.
#
#   Expected: every edge in the sink block's sources is still in its source block's targets.

        .text
        .hidden fa, fb, fz

        .globl  fz
        .type   fz, @function

        .globl  fa
        .type   fa, @function
        .p2align 4
fa:
        lea     TA(%rip), %rcx
        movslq  (%rcx,%rdi,4), %rax     # index %rdi is never bounded
        add     %rcx, %rax
        jmp     *%rax
.Lfa_c0: mov    $10, %eax
        ret
.Lfa_c1: mov    $11, %eax
        ret
.Lfa_c2: mov    $12, %eax
        ret
.Lfa_c3: mov    $13, %eax
        ret
        .size   fa, .-fa

        .globl  fb
        .type   fb, @function
        .p2align 4
fb:
        cmp     $3, %edi
        ja      .Lfb_def
        lea     TB(%rip), %rcx
        movslq  (%rcx,%rdi,4), %rax
        add     %rcx, %rax
        jmp     *%rax
.Lbogus:                                # dead bytes, reached only by fa's over-read
        nop
        .byte   0xe9                    # jmp rel32 to far outside the code: a sink edge
        .long   0x40000000
        .fill   10, 1, 0x90
.Lfb_c0: mov    $20, %eax
        ret
.Lfb_c1: mov    $21, %eax
        ret
.Lfb_c2: mov    $22, %eax
        ret
.Lfb_c3: mov    $23, %eax
        ret
.Lfb_def: xor   %eax, %eax
        ret
        .size   fb, .-fb

        .p2align 4
fz:
        ret
        .size   fz, .-fz

        .section .rodata
        .p2align 2
TA:     .long   .Lfa_c0 - TA, .Lfa_c1 - TA, .Lfa_c2 - TA, .Lfa_c3 - TA
TB:     .long   .Lfb_c0 - TB, .Lfb_c1 - TB, .Lfb_c2 - TB, .Lfb_c3 - TB
        .long   0x7fffffff, 0x7fffffff  # not code: every read stops here

        .section .note.GNU-stack,"",@progbits
