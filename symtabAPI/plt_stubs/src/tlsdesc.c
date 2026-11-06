/* A shared library whose PLT relocations hold a TLSDESC relocation beside an
   ordinary JUMP_SLOT.  The TLSDESC one has no PLT stub of its own, but the
   rewriter must still write it back. */
extern __thread int ext_tls;
extern int ext_func(int);
int get_ext(void) { return ext_tls; }
int call_ext(int x) { return ext_func(x) + 1; }
