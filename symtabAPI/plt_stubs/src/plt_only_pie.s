# A position independent executable whose only dynamic relocations are PLT
# ones: one JUMP_SLOT for bar, from libplt_only.so.
        .text
        .globl  _start
        .type   _start, @function
_start:
        li      a0, 1
        call    bar@plt
        ret
        .size   _start, .-_start
