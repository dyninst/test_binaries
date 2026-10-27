#include "shapes.h"

int main() {
  gmap[1] = 2.0;
  gptr = std::make_shared<Shape>();
  gfun = [] { return gshape.area(); };
  return static_cast<int>(gfun() + gptr->area()) + (gnode._M_left != nullptr);
}
