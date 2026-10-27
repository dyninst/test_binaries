/* C lets two units define different types with the same tag. */
struct Shape {
  int x;
} ga;

int main(void) { return ga.x; }
