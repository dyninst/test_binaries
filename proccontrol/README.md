Mutatees for the ProcControl regression tests that single-step a thread
through a load-reserve/store-conditional sequence.

ProcControl cannot hardware-single-step these sequences on Power and AArch64
(a trap between the reserve and the store-conditional loses the reservation),
so it emulates the step by running the thread to breakpoints at the
sequence's exits. Each test needs a mutatee with one such sequence in
hand-written assembly, so there is one source and one binary per
architecture.

| directory | dyninst test | what the sequence does |
|---|---|---|
| `atomicSeqInnerBranch` | `proccontrol_atomic_seq_inner_branch` | branches back to the reserve before the store-conditional, so a branch target lies inside the sequence |
| `refusedStepAtBreakpoint` | `proccontrol_refused_step_at_breakpoint` | puts 25 instructions between the reserve and the store-conditional, beyond ProcControl's 24-instruction scan, so the emulated step is refused |
| `stepOffDuringEmulatedStep` | `proccontrol_step_off_during_emulated_step` | waits in a futex on a flag between the reserve and the store-conditional, so an emulated step stays in flight until the mutator sets the flag |

Each directory has `src/aarch64.c` and `src/ppc64le.c` and the binaries
`aarch64` and `ppc64le` built from them. A test runs the binary for its
host's architecture and reports itself skipped on any other.

The tests find the sequences through global labels (listed in each
directory's README), so the binaries keep their symbol tables. Each exits
with code 0 when it runs to the end with nothing changed by the mutator.

## Rebuilding

`./build.sh`, on an aarch64 or a ppc64le host, rebuilds that architecture's
binaries in every directory. The binaries are executed, so they are linked
dynamically against an old glibc; a binary linked against glibc 2.34 or later
needs `__libc_start_main@GLIBC_2.34` and does not start on an older one. The
committed binaries need nothing newer than `GLIBC_2.17`.

| binaries | host | compiler | glibc |
|---|---|---|---|
| `ppc64le` | RHEL 8 | GCC 8.5.0 | 2.28 |
| `aarch64` | Ubuntu 20.04 | GCC 10.5.0 | 2.31 |

Built twice, in two different directories, each architecture's binaries came
out byte-identical.
