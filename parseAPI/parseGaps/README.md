Parse a stripped aarch64 binary that utilizes el0.
Exception Level registers are used by system instructions to change the privilege level.

See https://support.arm.com/documentation/102412/0103/Privilege-and-Exception-levels/Exception-levels
for details.

This was originally reported by https://github.com/dyninst/dyninst/issues/1186 with the failure

```
instructionAPI/src/aarch64_opcode_tables.C:3839:
  static Dyninst::MachRegister
  Dyninst::InstructionAPI::InstructionDecoder_aarch64::sysRegMap(unsigned int):
  Assertion !"tried to access system register not accessible in EL0"' failed.
```
