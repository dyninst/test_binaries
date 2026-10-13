#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    if (argc > 99)
        abort();
    if (argc > 1 && strlen(argv[1]) > 99)
        exit(1);
    printf("plt stubs %d\n", argc);
    return 0;
}
