// Built with GCC at -O2: erase() never uses `this` except to call itself, so
// GCC's IPA-SRA clone (erase.isra.0) drops it. Where the clone recurses,
// `this` is described as the caller's argument: DW_OP_GNU_parameter_ref.
#include <cstdio>

struct Node {
  Node *left, *right;
  long value;
};

struct Tree {
  Node *root = nullptr;
  long size = 0;

  __attribute__((noinline)) void erase(Node *n) {
    while (n) {
      erase(n->right);
      Node *l = n->left;
      delete n;
      n = l;
    }
  }

  ~Tree() { erase(root); }
};

int main(int argc, char **) {
  Tree t;
  for (int i = 0; i < argc + 3; i++) t.root = new Node{t.root, nullptr, i};
  std::printf("%ld\n", t.root->value);
  return 0;
}
