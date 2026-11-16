/* Globals of known sizes, for symtabAPI_global_vars. See README.md. */
#include <stdint.h>

struct pair {
  int32_t a;
  int64_t b;
};

int8_t g_i8 = 1;
int16_t g_i16 = 2;
int32_t g_i32 = 3;
int64_t g_i64 = 4;
volatile long g_vlong = -1;
struct pair g_pair = {5, 6};
int32_t g_array[10] = {7};
int64_t g_bss;
static int32_t g_static = 8;

/* A parameter and a local on the stack: their locations are DW_OP_fbreg, so
   only DW_AT_decl_file decides whether they are kept. */
int twice(int value) {
  int doubled = value * 2;
  return doubled;
}

int counter(void) {
  static int calls;
  return ++calls;
}

int main(void) {
  return twice(1) + counter() + g_i8 + g_i16 + g_i32 + (int)g_i64 + (int)g_vlong + g_pair.a + g_array[0] + (int)g_bss + g_static;
}
