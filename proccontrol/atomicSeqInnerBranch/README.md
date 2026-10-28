Mutatee for `proccontrol_atomic_seq_inner_branch` (dyninst/dyninst#2452).

`inner_seq` is a nop followed by a load-reserve/store-conditional sequence
whose retry branch (`cbz` on AArch64, `beq-` on Power) sits before the
store-conditional and targets the reserve, so a branch target lies inside the
sequence. The word is nonzero, so the branch is never taken. The test puts a
breakpoint on the nop, single-steps into the sequence, and requires the
emulated step to come out after the store-conditional.

Labels the test looks up: `inner_seq` (the nop), `inner_seq_reserve`,
`inner_seq_after_store`.

The program exits with code 0 when `inner_seq` returns the old value (5) and
stored the new one (9).
