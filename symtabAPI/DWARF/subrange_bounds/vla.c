/* Subrange shapes whose bounds are only known at run time (C99 VLAs),
   plus constant-bound controls. */
extern void sink(void *p);

__attribute__((noinline)) void vla_1d(int n) {
  int a[n];
  sink(a);
}

__attribute__((noinline)) void vla_2d(int n, int m) {
  int b[n][m];
  sink(b);
}

__attribute__((noinline)) void fixed(void) {
  int c[10];
  int d[3][4];
  sink(c);
  sink(d);
}

void sink(void *p) { __asm__ volatile("" : : "r"(p) : "memory"); }

int main(int argc, char **argv) {
  (void)argv;
  vla_1d(argc + 4);
  vla_2d(argc + 1, argc + 2);
  fixed();
  return 0;
}
