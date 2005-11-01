
generic configuration MSP430RegC(reg_type,addr)
{
  provides interface MSP430Reg<reg_type> as Reg;
}
implementation
{
  components new MSP430RegM(reg_type,addr) as MSP430Reg;
  Reg = MSP430Reg.Reg;
}

