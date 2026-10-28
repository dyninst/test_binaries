Mutatee for `proccontrol_refused_step_at_breakpoint` (dyninst/dyninst#2525).

`refused_seq` is a load-reserve, 25 nops, and the store-conditional: one
instruction more than ProcControl scans for the end of a sequence (24), so
an emulated single step from the reserve is refused. The test puts a
breakpoint on the reserve and single-steps from it; the refused step used to
leave the breakpoint step-over half set up and hang the event loop.

Label the test looks up: `refused_seq_start` (the reserve).

The program exits with code 0 when `refused_seq` returns the old value (5)
and stored the new one (9).
