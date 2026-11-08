struct pair { int a; long b; };
struct pair g_pair = {1, 2};

int add(int x, int y) { return x + y; }

int main(void) { return add(g_pair.a, (int)g_pair.b); }
