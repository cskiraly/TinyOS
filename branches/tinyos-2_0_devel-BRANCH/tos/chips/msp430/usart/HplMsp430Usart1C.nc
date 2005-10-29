
configuration HplMsp430Usart1C {
  provides interface HplMsp430Usart;
  provides interface Resource[ uint8_t id ];
}

implementation {

  components MainC;
  components HplMsp430Usart1P as HplUsartP;
  components MSP430GeneralIOC as GIO;
  components new FcfsArbiterC( "Msp430Usart1.Resource" ) as Arbiter;

  MainC.SoftwareInit -> Arbiter;
  HplMsp430Usart = HplUsartP;
  Resource = Arbiter;

  HplUsartP.SIMO -> GIO.SIMO1;
  HplUsartP.SOMI -> GIO.SOMI1;
  HplUsartP.UCLK -> GIO.UCLK1;
  HplUsartP.URXD -> GIO.URXD1;
  HplUsartP.UTXD -> GIO.UTXD1;
}
