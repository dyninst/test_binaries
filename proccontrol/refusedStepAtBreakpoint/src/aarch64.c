/*
 * A load-reserve whose store-conditional is 25 instructions later, beyond the scan for the
 * end of the sequence (24 instructions), so an emulated single step from the reserve is
 * refused.
 */

int refused_seq(volatile int *p, int newval);

__asm__(".text\n"
        ".globl refused_seq\n"
        ".type refused_seq, %function\n"
        "refused_seq:\n"
        ".globl refused_seq_start\n"
        "refused_seq_start:\n"
        "1:  ldxr  w2, [x0]\n"
        ".rept 25\n"
        "    nop\n"
        ".endr\n"
        "    stxr  w3, w1, [x0]\n"
        "    cbnz  w3, 1b\n"
        "    mov   w0, w2\n"
        "    ret\n"
        ".size refused_seq, .-refused_seq\n");

volatile int word = 5;

int main(void) {
  /* the old value is returned and the new one stored */
  return refused_seq(&word, 9) == 5 && word == 9 ? 0 : 1;
}
