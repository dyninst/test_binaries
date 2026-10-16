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

`riscv64/libzicfilp.so` is the library `riscv64/dyn.zicfilp` imports from.  The
test does not open it; it is here so the executable's `DT_NEEDED` can be
resolved by anyone looking at it by hand.

### How they were built

All but one are built from `src/plt_stubs.c` in this directory, as

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
call actually lands on, which is what ParseAPI's linkage table has to name.
They are the same addresses except where a two-level PLT puts the second in
`.plt.sec`, and each is read from the linker's own record rather than from
Dyninst.

`ppc64le/dyn` has no `.linkage` file: its call stubs carry no `@plt` label for
an expectation to be read from.  The `.linkage` files also leave out the
`.plt.got` entry that `x86_64/dyn.pie`, `i686/dyn.pie` and `i686/dyn.pie.cet`
each have -- the relocation behind one is in `.rela.dyn` rather than
`.rela.plt`, and Dyninst's scan of that section skips it when the section is
16 bytes or smaller, which is every case here.

### Two things that are not mistakes

`x86_64/dyn.cet` and `i686/dyn.cet` expect addresses in `.plt`, not the
`.plt.sec` addresses `objdump` labels.  Both are real: `.plt` holds the entry
the relocation belongs to, `.plt.sec` the one calls go through, and ParseAPI
maps names to the latter in a separate pass.

ParseAPI names the `.plt.sec` stubs of `x86_64/dyn.cet` but not those of
`i686/dyn.cet` or `i686/dyn.pie.cet`: the pass in `SymtabCodeSource::
init_linkage` that does it is gated on x86-64.  The binding table, which is
what the test reads, names the `.plt` entries in all three, so the tests pass
either way; the two 32-bit files are kept as the reproducer for that gap.

`ppc64le/dyn` yields twelve entries where six stubs exist: six from the
`.plt_call` symbols, which are the stub addresses the `.expected` file names,
and six more in the data `.plt` that the generic path adds.  Only the first six
are asserted.
