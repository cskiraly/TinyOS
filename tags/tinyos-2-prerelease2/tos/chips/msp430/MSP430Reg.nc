
interface MSP430Reg<reg_type>
{
  command reg_type get();
  command reg_type set( reg_type v );
  command reg_type and( reg_type v );
  command reg_type or( reg_type v );
  command reg_type inc();
  command reg_type dec();
  command reg_type add( reg_type v );
  command reg_type sub( reg_type v );
}

