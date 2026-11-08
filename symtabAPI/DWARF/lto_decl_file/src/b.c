#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

__attribute__((noipa)) int64_t scale(int32_t value, size_t factor) {
  static int calls;
  calls++;
  return value * (int64_t)factor + calls;
}
