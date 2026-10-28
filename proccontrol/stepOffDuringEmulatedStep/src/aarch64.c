/*
 * A load-reserve/store-conditional sequence that the thread cannot leave while the flag is 0.
 * A thread single-stepped into it stays there with ProcControl's emulated single step in
 * flight, until the mutator sets the flag.
 */

int window(volatile int *flag, int val);

/*
 * The reservation is held across a futex wait on the flag instead of a spin loop: the scan
 * puts a breakpoint at every branch target in the sequence, and the target of a spin loop's
 * back branch is inside it, so the thread would report a step on every iteration instead of
 * leaving the emulated step in flight.  The wait returns once the flag is no longer 0 (a
 * restarted wait sees the mutator's write).  The store usually fails because the stop cleared
 * the reservation; the flag is returned either way.
 */
__asm__(".text\n"
        ".globl window\n"
        ".type window, %function\n"
        "window:\n"
        "    mov   x9, x0\n"
        "    mov   w10, w1\n"
        ".globl window_seq\n"
        "window_seq:\n"
        "    ldaxr w11, [x9]\n"
        "    mov   x1, #0\n" /* FUTEX_WAIT */
        "    mov   x2, #0\n" /* while *flag == 0 */
        "    mov   x3, #0\n" /* no timeout */
        "    mov   x8, #98\n" /* __NR_futex */
        "    svc   #0\n"
        "    stxr  w12, w10, [x9]\n"
        ".globl window_end\n"
        "window_end:\n"
        "    ldr   w0, [x9]\n"
        "    ret\n"
        ".size window, .-window\n");

volatile int flag = 0;

/* No globals, so on ppc64le the global and local entry points coincide. */
__attribute__((noinline, used)) void before_window(void) { __asm__ volatile("" ::: "memory"); }

int main(void) {
  before_window();
  /* the mutator sets the flag to 1; the sequence may store 2 over it */
  int seen = window(&flag, 2);
  return seen == 1 || seen == 2 ? 0 : 1;
}
