
generic module MSP430RegM( type reg_type, uint16_t addr )
{
  provides interface MSP430Reg<reg_type> as Reg;
}
implementation
{
  MSP430_NORACE3(reg_type,reg,addr);

  command reg_type Reg.get()
  {
    return reg;
  }

  command reg_type Reg.set( reg_type v )
  {
    return reg = v;
  }

  command reg_type Reg.and( reg_type v )
  {
    return reg &= v;
  }

  command reg_type Reg.or( reg_type v )
  {
    return reg |= v;
  }

  command reg_type Reg.inc()
  {
    return ++reg;
  }

  command reg_type Reg.dec()
  {
    return --reg;
  }

  command reg_type Reg.add( reg_type v )
  {
    return reg += v;
  }

  command reg_type Reg.sub( reg_type v )
  {
    return reg -= v;
  }
}

