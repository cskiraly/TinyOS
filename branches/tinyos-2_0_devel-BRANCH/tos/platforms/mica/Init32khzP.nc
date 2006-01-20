configuration Init32khzP { }
implementation {
  components PlatformC, HplAtm128Timer1C as HWTimer,
    new Atm128TimerInitC(uint16_t, ATM128_CLK8_DIVIDE_256) as Init32khz;

  PlatformC.SubInit -> Init32khz;
  Init32khz.Timer -> HWTimer;
}
