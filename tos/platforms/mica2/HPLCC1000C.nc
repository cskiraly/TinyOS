configuration HPLCC1000C {
  provides {
    interface StdControl as RssiControl;
    interface AcquireDataNow as RssiAdc;
    interface HPLCC1000Spi;
    interface HPLCC1000;
  }
}
implementation {
  components HPLCC1000P, HPLCC1000SpiC;
  components new AdcNowChannelC(CHANNEL_RSSI) as RssiChannel, AdcC;

  HPLCC1000 = HPLCC1000P;
  HPLCC1000Spi = HPLCC1000SpiC;
  RssiControl = AdcC;
  RssiAdc = RssiChannel;

  // HPLCC1000M, HPLCC1000SpiM are wired in HPLCC1000InitC which is always
  // included (see MotePlatformC.nc).
}
