/* Globals of 1, 2 and 8 bytes, each followed by a neighbour. A mutator stores
   to g_char, g_short and g_long; the program prints all of them, so a store
   wider than its variable shows up in the neighbour. */
#include <stdio.h>

volatile char g_char = 1;
volatile char g_char_next[3] = {2, 3, 4};
volatile short g_short = 5;
volatile short g_short_next = 6;
volatile long g_long = -1;

int main(void) {
  printf("g_char=%d next=%d,%d,%d g_short=%d next=%d g_long=%#lx\n", g_char, g_char_next[0], g_char_next[1],
         g_char_next[2], g_short, g_short_next, (unsigned long)g_long);
  return 0;
}
