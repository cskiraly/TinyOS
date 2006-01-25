configuration MicaBusC {
  provides {
    interface GeneralIO as PW0;
    interface GeneralIO as PW1;
    interface GeneralIO as PW2;
    interface GeneralIO as PW3;
    interface GeneralIO as PW4;
    interface GeneralIO as PW5;
    interface GeneralIO as PW6;
    interface GeneralIO as PW7;
  }
}
implementation {
  components HplAtm128GeneralIOC as Pins;

  PW0 = Pins.PortC0;
  PW1 = Pins.PortC1;
  PW2 = Pins.PortC2;
  PW3 = Pins.PortC3;
  PW4 = Pins.PortC4;
  PW5 = Pins.PortC5;
  PW6 = Pins.PortC6;
  PW7 = Pins.PortC7;
}
