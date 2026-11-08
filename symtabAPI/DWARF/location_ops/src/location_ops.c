/* Built at -O2: variables whose locations need DWARF operations beyond a fixed
   address, a register or a frame offset. Each function is named for the
   operation it is meant to produce; README.md lists what each compiler gives. */
#include <stdio.h>

__attribute__((noinline)) void sink(long v) { __asm__ volatile("" ::"r"(v)); }
__attribute__((noinline)) void sink_d(double v) { __asm__ volatile("" ::"x"(v)); }

/* x is dead after the call; afterwards its value is the one it had on entry:
   DW_OP_entry_value. */
__attribute__((noinline)) long entry_value(long x) {
  sink(1);
  return 0;
}

struct point {
  long x, y;
};

/* pt lives only in registers, so p points at nothing in memory:
   DW_OP_implicit_pointer. */
__attribute__((noinline)) long implicit_ptr(long a) {
  struct point pt = {a, a + 1};
  struct point *p = &pt;
  sink(p->x);
  return p->y;
}

/* sum starts as the constant 0.0 before the loop keeps it in a register:
   DW_OP_implicit_value for that first range. */
__attribute__((noinline)) double implicit_val(double const *v, int n) {
  double sum = 0;
  for (int i = 0; i < n; i++) {
    sink(i);
    sum += v[i];
  }
  return sum;
}

/* c is a narrowed copy of a wider value: DW_OP_convert. */
__attribute__((noinline)) int narrowed(long v) {
  char c = (char)v;
  sink(c);
  return c;
}

/* unused is dropped from the clone GCC makes of this function; its value is
   the caller's argument: DW_OP_GNU_parameter_ref. */
static __attribute__((noinline)) long param_ref(long used, long unused) {
  sink(used);
  return used * 2;
}

int main(int argc, char **argv) {
  (void)argv;
  double vals[4] = {1, 2, 3, 4};
  long r = param_ref(argc, argc + 7) + param_ref(argc + 1, argc + 9);
  printf("%ld %ld %f %d %ld\n", entry_value(argc), implicit_ptr(argc), implicit_val(vals, argc), narrowed(argc * 300), r);
  return 0;
}
