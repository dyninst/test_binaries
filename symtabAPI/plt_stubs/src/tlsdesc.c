/* A shared library whose .rela.plt holds a TLSDESC relocation beside an
   ordinary JUMP_SLOT.  On aarch64 the TLSDESC one has no PLT stub of its own,
   but the rewriter must still write it back to .rela.plt. */
extern __thread int ext_tls;
static __thread int own_tls = 3;
extern int ext_func(int);
int get_ext(void) { return ext_tls; }
int get_own(void) { return own_tls; }
int call_ext(int x) { return ext_func(x) + 1; }
