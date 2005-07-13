configuration HPLCC1000C {
  provides {
    interface StdControl as RssiControl;
    interface AcquireDataNow as RSSIADC;
    interface HPLCC1000Spi;
    interface HPLCC1000;
  }
}
implementation {
  components HPLCC1000M, HPLCC1000SpiM;
  components new ADCNowChannelC(CHANNEL_RSSI) as RSSIChannel, ADCC;

  HPLCC1000 = HPLCC1000M;
  HPLCC1000Spi = HPLCC1000SpiM;
  RssiControl = ADCC;
  RSSIADC = RSSIChannel;

  // HPLCC1000M, HPLCC1000SpiM are wired in HPLCC1000InitC which is always
  // included (see MotePlatformC.nc).
}
