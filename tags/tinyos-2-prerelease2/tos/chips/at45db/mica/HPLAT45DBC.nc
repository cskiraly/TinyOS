configuration HPLAT45DBC {
  provides {
    interface StdControl;
    interface HPLAT45DB;
  }
}
implementation {
  components HPLAT45DBByte, HPLFlash;

  StdControl = HPLFlash;
  HPLAT45DB = HPLAT45DBByte;

  HPLAT45DBByte.FlashSPI -> HPLFlash;
  HPLAT45DBByte.FlashIdle -> HPLFlash;
  HPLAT45DBByte.getCompareStatus -> HPLFlash;
  HPLAT45DBByte.FlashSelect -> HPLFlash;
}
