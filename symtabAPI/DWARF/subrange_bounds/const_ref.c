/* VLAs whose size the optimizer proves constant. clang describes the bound
   as a reference to an artificial variable with DW_AT_const_value; gcc as a
   DWARF expression that is a single constant operation. */
extern void sink(void *p);

__attribute__((noinline)) void const_vla(void) {
  int n = 7;
  int a[n];
  sink(a);
}

__attribute__((noinline)) void const_vla_300(void) {
  int n = 300;
  int b[n];
  sink(b);
}

void sink(void *p) { __asm__ volatile("" : : "r"(p) : "memory"); }

int main(void) {
  const_vla();
  const_vla_300();
  return 0;
}
