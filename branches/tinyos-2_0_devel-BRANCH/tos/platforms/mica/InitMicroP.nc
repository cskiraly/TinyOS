configuration InitMicroP { }
implementation {
  components PlatformC, HplAtm128Timer3C as HWTimer,
    new Atm128TimerInit(uint16_t, ATM128_CLK8_DIVIDE_8) as InitMicro;

  PlatformC.SubInit -> InitMicro;
  InitMicro.Timer -> HWTimer;
}
