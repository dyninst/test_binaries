int by_ref(int &r, const double &d, int *p) { return r + (int)d + *p; }

int main() {
  int i = 1, j = 2;
  double d = 3;
  return by_ref(i, d, &j);
}
