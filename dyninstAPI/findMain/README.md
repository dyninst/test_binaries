## Test binaries for `image::findMain()`

There are no GPU binaries because NVIDIA and AMD don't have a `main`
as their entry point.

Each binary is generated from the input

```C
#include <stdio.h>

int main() {
  printf("Hello");
  return 0;
}
```

Each was built with the gcc-11 cross-compilers from Ubuntu 22.04

```
riscv64-linux-gnu-gcc-11 (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
x86_64-linux-gnu-gcc-11 (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0
i686-linux-gnu-gcc-11 (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0
powerpc64-linux-gnu-gcc-11 (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
aarch64-linux-gnu-gcc-11 (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0
```

Flags used to build each variant

| linkage | PIE | flags |
| ------- | --- |----- |
| dynamic | N | -no-pie  |
| dynamic | Y | -pie  |
| static | N | -static -no-pie  |
| static | Y | -static-pie  |
