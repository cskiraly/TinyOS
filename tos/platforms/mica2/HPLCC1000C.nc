configuration HPLCC1000C {
  provides {
    //XXX: interface Init; (currently just a command in HPLCC1000)
    interface AcquireDataNow as RSSIADC;
    interface CC1000Spi;
    interface HPLCC1000;
  }
}
implementation {
  components HPLCC1000M, HPLCC1000SpiM;
  components new ADCNowChannelC(CHANNEL_RSSI) as RSSIChannel;

  HPLCC1000 = HPLCC1000M;
  CC1000Spi = HPLCC1000SpiM;
  RSSIADC = RSSIChannel;
}
