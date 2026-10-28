Mutatee for `proccontrol_step_off_during_emulated_step` (dyninst/dyninst#2453).

`window` holds a reservation across a `futex(FUTEX_WAIT)` on `flag` and
leaves through the store-conditional once `flag` is no longer 0. It has no
branch inside the sequence: ProcControl puts a breakpoint at every branch
target in it, so a spin loop back to the reserve would report a step on
every iteration instead of keeping one emulated step in flight. On ppc64le
the values live in r30 and r31, saved in the red zone, because `sc` may
clobber r0 and r4-r12.

The test puts a breakpoint on `before_window`, single-steps the thread onto
`window_seq`, stops the process with the emulated step in flight, turns
single-step mode off, writes 1 to `flag` and continues. No further
SingleStep event may arrive.

Labels the test looks up: `before_window`, `window_seq` (the reserve),
`window_end` (just after the store-conditional), `flag`.

The program exits with code 0 when `window` returns 1 or 2 (the mutator's 1,
or the 2 the store-conditional wrote over it).
