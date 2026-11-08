#include <stddef.h>
#include <stdint.h>
int64_t scale(int32_t value, size_t factor);

int main(int argc, char **argv) {
  (void)argv;
  return scale(argc, 3);
}
