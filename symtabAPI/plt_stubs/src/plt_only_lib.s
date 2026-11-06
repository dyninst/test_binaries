# A shared library whose only dynamic relocations are PLT ones: one
# JUMP_SLOT for foo, which another library defines.
        .text
        .globl  bar
        .type   bar, @function
bar:
        addi    sp, sp, -16
        sd      ra, 8(sp)
        call    foo@plt
        addi    a0, a0, 1
        ld      ra, 8(sp)
        addi    sp, sp, 16
        ret
        .size   bar, .-bar
