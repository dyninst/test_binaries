# jt_reread.s: a jump table read twice with different extents (x86_64, PIC).
#
#   fa reads its table TA with an index it never bounds, so the parser reads up to 256
#   entries and runs past TA's 4 entries into TB.  TB's first entry, taken relative to TA,
#   lands exactly on fb's dispatch lea (.Lfb_lea = .Lfb_c0 - 16 = .Lfb_c0 - (TB - TA)), so fa's
#   frame parses fb's dispatch block as its own and analyzes fb's jump in fa's context:
#   without fb's `and $3`, which is in the block before, there is no bound, and the read
#   runs from TB into TC (2 bogus targets, fc's cases shifted by -16).
#
#   fa reads TA on a path that does not go through its call to g.  fa and g call each other,
#   so fa's frame then waits on g until the cycle is broken.  By then
#   fb has been parsed and its fallthrough into .Lfb_lea exists; when fa's frame finishes, the
#   value-driven re-read of fb's jump sees the `and $3`, reads 4 entries and replaces the
#   long record.  fc's switch makes TC a known table start, so finalize_jump_tables can trim
#   fb's jump at TC -- if the record still lists the entries it read past TB.
#
#   Expected CFG: the jump at .Lfb_jmp has exactly the 4 targets .Lfb_c0..fb_c3.

        .text
        .hidden fa, g, fb, fc, fz      # direct calls, no PLT

        .globl  fz                      # last symbol: hint gap 0, parsed first, does nothing
        .type   fz, @function

        .globl  fa
        .type   fa, @function
        .p2align 4
fa:
        push    %rbp
        mov     %rsp, %rbp
        test    %esi, %esi
        jne     .Lfa_call
        lea     TA(%rip), %rcx          # the dispatch does not wait for the call below
        movslq  (%rcx,%rdi,4), %rax     # index %rdi is never bounded
        add     %rcx, %rax
        jmp     *%rax
.Lfa_c0:  mov     $10, %eax
        jmp     .Lfa_call
.Lfa_c1:  mov     $11, %eax
        jmp     .Lfa_call
.Lfa_c2:  mov     $12, %eax
        jmp     .Lfa_call
.Lfa_c3:  mov     $13, %eax
        jmp     .Lfa_call
.Lfa_call:
        call    g                       # fa -> g -> fa: a cycle of unknown return statuses keeps
        jmp     .Lfa_call               # fa's frame open until the cycle is broken, after fb has
                                        # been parsed.  fa has no ret, so no path makes it RETURN
                                        # (which would end its frame's run early).
        .p2align 8                      # frames start in descending hint-gap order: g, then fa,
        .size   fa, .-fa                # then fb

        .globl  g
        .type   g, @function
        .p2align 4
g:
        call    fa                      # g starts first, so fa's frame exists when fa calls g and
        ret                             # fa only delays the fallthrough; g returns only after fa
        .skip   0x300                   # the largest hint gap
        .size   g, .-g

        .globl  fb
        .type   fb, @function
        .p2align 4
fb:
        movzbl  (%rsi), %edx
        and     $3, %edx                # the real bound: 0..3
.Lfb_lea:
        lea     TB(%rip), %rcx          # 7 bytes
        movslq  (%rcx,%rdx,4), %rsi     # 4 bytes
        add     %rcx, %rsi              # 3 bytes
.Lfb_jmp:
        jmp     *%rsi                   # 2 bytes: .Lfb_c0 = .Lfb_lea + 16
.Lfb_c0:  mov     $20, %eax
        ret
.Lfb_c1:  mov     $21, %eax
        ret
.Lfb_c2:  mov     $22, %eax
        ret
.Lfb_c3:  mov     $23, %eax
        ret
        .size   fb, .-fb

        .globl  fc
        .type   fc, @function
        .p2align 4
fc:
        cmp     $1, %edi
        ja      .Lfc_def
        lea     TC(%rip), %rcx
        movslq  (%rcx,%rdi,4), %rax
        add     %rcx, %rax
        jmp     *%rax
        .fill   16, 1, 0x90             # 16 nops: .Lfc_c0 - 16 and .Lfc_c1 - 16 are instructions
.Lfc_c0:  mov     $30, %eax
        ret
        .fill   10, 1, 0x90
.Lfc_c1:  mov     $31, %eax
        ret
.Lfc_def: xor     %eax, %eax
        ret
        .size   fc, .-fc

        .p2align 4
fz:
        ret
        .size   fz, .-fz

        .section .rodata
        .p2align 2
TA:     .long   .Lfa_c0 - TA, .Lfa_c1 - TA, .Lfa_c2 - TA, .Lfa_c3 - TA
TB:     .long   .Lfb_c0 - TB, .Lfb_c1 - TB, .Lfb_c2 - TB, .Lfb_c3 - TB
TC:     .long   .Lfc_c0 - TC, .Lfc_c1 - TC
        .long   0x7fffffff, 0x7fffffff  # not code: every read stops here

        .section .note.GNU-stack,"",@progbits
