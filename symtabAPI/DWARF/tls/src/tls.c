_Thread_local int t_int = 7;
_Thread_local long t_long = 8;
int g_int = 9;

int main(void) { return t_int + (int)t_long + g_int; }
