extern void free(void*);
extern int a(void),b(void),c(void),d(void),e(void);
int sw(int x){ switch(x){case 0:return a();case 1:return b();case 2:return c();
  case 3:return d();case 4:return e();case 5:return a()+1;case 6:return b()+2;
  case 7:return c()+3;case 8:return d()+4;default:return 0;} }
void f(void*p){ free(p); }
