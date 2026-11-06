## Test binaries for the function binding table

Each file is a dynamically linked executable that imports a few functions, so
the linker gives it a `.plt` and a `.rel[a].plt`.  What the test reads is the
address SymtabAPI records for each stub -- `Symtab::getFuncBindingTable()` --
and how those addresses are laid out differs by architecture and by the
protection features the binary was built with.

The binaries are read, never run.  SymtabAPI parses any architecture, so one
x86-64 runner checks all of them; that is the point of keeping them here
rather than building them during the test.

### What each one is for

| file | pins |
| ---- | ---- |
| `x86_64/dyn` | the ordinary PLT |
| `x86_64/dyn.cet` | the two-level PLT of Intel CET, where calls go through `.plt.sec` |
| `x86_64/dyn.pie` | the same, position independent, with a `.plt.got` entry no `.rela.plt` relocation names |
| `i686/dyn` | the architecture whose `.plt` `sh_entsize` GNU ld still writes as 4, for compatibility with the UnixWare linker |
| `i686/dyn.cet` | the same, with the second PLT; here the lazy entries push a byte offset into `.rel.plt` rather than an index |
| `i686/dyn.pie` | position independent, where every entry reaches the GOT through `%ebx` |
| `i686/dyn.pie.cet` | both at once, which is the default on several distributions: a `.plt.sec` stub whose `jmp *disp(%ebx)` does not name the GOT slot it uses, and a `.plt.got` beside it |
| `aarch64/dyn` | `sh_entsize` zero, which GNU ld writes deliberately (binutils PR ld/26312), and 16-byte stubs |
| `aarch64/dyn.bti-pac` | 24-byte stubs, each beginning with the `bti c` a call lands on |
| `ppc64le/dyn` | ELFv2, where `.plt` holds data and the call stubs are in `.text`, found through `.plt_call` symbols |
| `riscv64/dyn` | a 32-byte PLT header, and a binary whose only dynamic relocations are its PLT's, so `DT_RELA` and `DT_JMPREL` name the same section |
| `riscv64/dyn.zicfilp` | the 48-byte header of the Zicfilp PLT, for landing-pad control flow integrity |
| `aarch64/libtlsdesc.so` | a shared library whose `.rela.plt` holds a TLSDESC relocation, which has no stub of its own, beside an ordinary one |
| `x86_64/libtlsdesc.so` | the same for x86-64 (`-mtls-dialect=gnu2`), where the relocation's slot in the count is the lazy TLSDESC trampoline |
| `i686/libtlsdesc.so` | the same for i686, in `.rel.plt` |
| `riscv64/libplt_only.so` | `DT_RELA` and `DT_JMPREL` naming the same section, as in `riscv64/dyn`, in a shared library |
| `riscv64/dyn.pie.plt_only` | the same in a position independent executable |

`riscv64/libzicfilp.so` is the library `riscv64/dyn.zicfilp` imports from.  The
test does not open it; it is here so the executable's `DT_NEEDED` can be
resolved by anyone looking at it by hand.  `riscv64/libplt_only.so` is likewise
the library `riscv64/dyn.pie.plt_only` imports `bar` from.

The two `plt_only` files are for dyninst/dyninst#2588's
`symtabAPI_rela_jmprel_shared` test, which rewrites them.  `emitElf` moves a
shared library or PIE up by a page, which an executable linked `-no-pie` does
not exercise.

### How they were built

The executables other than `riscv64/dyn.zicfilp` and `riscv64/dyn.pie.plt_only`
are built from `src/plt_stubs.c` in this directory, as

```
$CC $EXTRA -fcf-protection=none -no-pie -o <arch>/dyn src/plt_stubs.c
```

with the variants differing only in flags:

| variant | flags |
| ------- | ----- |
| `dyn` | `-fcf-protection=none -no-pie` |
| `dyn.cet` | `-fcf-protection=full -no-pie` |
| `dyn.pie` | `-fcf-protection=none -fPIE -pie` |
| `dyn.bti-pac` | `-mbranch-protection=standard -no-pie -Wl,-z,force-bti -Wl,-z,pac-plt` |

`-mbranch-protection` alone is not enough for the last of those: it governs the
code the compiler emits, while which PLT the linker builds is settled by a GNU
property that the C runtime files do not carry, so without `-z force-bti` and
`-z pac-plt` the linker quietly builds the ordinary 16-byte stub.

`riscv64/dyn.zicfilp` cannot be built that way at all, for the same reason
carried further: the linker uses the Zicfilp PLT only when every input carries
`GNU_PROPERTY_RISCV_FEATURE_1_CFI_LP_UNLABELED`, and the C runtime files do
not.  It is assembled from `src/zicfilp_exe.s` and `src/zicfilp_lib.s`, which
declare the property by hand, and linked without a C library.  It needs
binutils 2.45 or newer; an older linker accepts the property and builds the
ordinary PLT.

| arch | host | distribution | compiler | linker |
| ---- | ---- | ------------ | -------- | ------ |
| x86_64, i686 | coriander | Ubuntu 20.04.6 | gcc 9.4.0 (`-m32` for i686) | ld 2.34 |
| aarch64 | hopper2 | RHEL 9.8 | gcc 11.5.0 | ld 2.35.2 |
| ppc64le | llnl | RHEL 8.8 | gcc 8.5.0 | ld 2.30 |
| riscv64 | fireflyk3-1 | Ubuntu 26.04 | gcc 15.2.0 | ld 2.46 |

The three `libtlsdesc.so` files are built from `src/tlsdesc.c` without a C
library, on an x86-64 host running Rocky Linux 8.8. aarch64 uses clang 15.0.7
and a GNU ld 2.46 built for aarch64; x86_64 and i686 use gcc 12.2.1 and GNU ld
2.38 from gcc-toolset-12:

```
clang --target=aarch64-linux-gnu -O2 -fPIC -c src/tlsdesc.c
ld -shared -o aarch64/libtlsdesc.so tlsdesc.o

gcc -O2 -fPIC -mtls-dialect=gnu2 -c src/tlsdesc.c
gcc -shared -nostdlib -o x86_64/libtlsdesc.so tlsdesc.o

gcc -m32 -O2 -fPIC -mtls-dialect=gnu2 -c src/tlsdesc.c
gcc -m32 -shared -nostdlib -o i686/libtlsdesc.so tlsdesc.o
```

`riscv64/libplt_only.so` and `riscv64/dyn.pie.plt_only` are assembled from
`src/plt_only_lib.s` and `src/plt_only_pie.s` and linked without a C library,
so their only dynamic relocations are one `R_RISCV_JUMP_SLOT` each.  GNU ld
then points `DT_RELA` at `.rela.plt`.  They were built on an x86-64 host with
binutils 2.46 configured `--target=riscv64-linux-gnu`:

```
as -march=rv64gc -o lib.o src/plt_only_lib.s
as -march=rv64gc -o pie.o src/plt_only_pie.s
ld -shared -soname libplt_only.so -o riscv64/libplt_only.so lib.o
ld -pie --allow-shlib-undefined --dynamic-linker /lib/ld-linux-riscv64-lp64d.so.1 \
   -o riscv64/dyn.pie.plt_only pie.o riscv64/libplt_only.so
```

`--allow-shlib-undefined` is needed because nothing defines the `foo` that
`libplt_only.so` imports; the files are never run.

### The expected addresses

Each binary has a `.expected` file beside it listing the stub address for each
imported function, one `0xADDR name` per line.  Every pair in it must appear in
the function binding table; a binary may have further entries, and `ppc64le/dyn`
does.

The addresses come from the linker's own record rather than from anything
Dyninst computed, by whichever of these the file allows:

  - the `<name@plt>` labels `objdump` puts on the stubs, which is most of them
  - for a two-level CET PLT, the relocation each lazy `.plt` entry pushes,
    since `objdump` labels the `.plt.sec` entries while the binding table
    names the `.plt` ones the relocations belong to
  - for ppc64le, the `.plt_call.<name>` symbol the linker leaves on each stub

### Two expectations, not one

`<binary>.expected` gives the stub each relocation belongs to, which is what
`Symtab::getFuncBindingTable()` returns.  `<binary>.linkage` gives the stub a
call lands on, which is what ParseAPI's linkage table has to name.  The two
differ only where Intel CET adds a second PLT in `.plt.sec`: calls go there,
while the relocations belong to the entries in `.plt`.  In `x86_64/dyn.cet`,
`printf` is at 0x401050 in `.expected` and 0x401090 in `.linkage`.  Both come
from what the linker recorded, not from Dyninst.

`ppc64le/dyn` has no `.linkage` file: its call stubs have no `@plt` label to
read.  The `.linkage` files also leave out the one `.plt.got` stub that
`x86_64/dyn.pie`, `i686/dyn.pie` and `i686/dyn.pie.cet` each have, because
Dyninst doesn't name it yet.

ParseAPI named the `.plt.sec` stubs only on x86-64 until dyninst/dyninst#2482,
which names them on i686 as well.  The `.linkage` files of `i686/dyn.cet` and
`i686/dyn.pie.cet` check that.

### Three things that are not mistakes

`x86_64/dyn.cet`, `i686/dyn.cet` and `i686/dyn.pie.cet` expect addresses in
`.plt`, not the `.plt.sec` addresses `objdump` labels, because the `.expected`
files give the entry the relocation belongs to.

`ppc64le/dyn` yields twelve entries where six stubs exist: six from the
`.plt_call` symbols, which are the stub addresses the `.expected` file names,
and six more in the data `.plt` that the generic path adds.  Only the first six
are asserted.

`objdump` labels the code at 0x2b0 in `aarch64/libtlsdesc.so` `ext_tls@plt`.
It is the lazy TLSDESC trampoline (`DT_TLSDESC_PLT`), not a stub for `ext_tls`:
`objdump` names the `.plt` entries in `.rela.plt` order.  The `.expected` files
of all three `libtlsdesc.so` leave `ext_tls` out.  In `x86_64/libtlsdesc.so`
the trampoline is at 0x1020, right after the one stub; i686 has none.
