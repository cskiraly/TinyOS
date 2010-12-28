interface HplSam3uTC{
  command void enableTC0(); // slclk
  command void enableTC1(); // slclk
  command void enableTC2(); // used for TMicro

  command void disableTC0();
  command void disableTC1();
  command void disableTC2();
}