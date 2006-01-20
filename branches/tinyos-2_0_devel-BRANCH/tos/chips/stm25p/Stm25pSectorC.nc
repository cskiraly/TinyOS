
configuration Stm25pSectorC {

  provides interface Resource as ClientResource[ storage_volume_t volume ];
  provides interface Stm25pSector as Sector[ storage_volume_t volume ];
  provides interface Stm25pVolume as Volume[ storage_volume_t volume ];

}

implementation {

  components MainC;

  components Stm25pSectorP as SectorP;
  ClientResource = SectorP;
  Sector = SectorP;
  Volume = SectorP;
  MainC.SoftwareInit -> SectorP;

  components new FcfsArbiterC( "Stm25p.Volume" ) as Arbiter;
  SectorP.Stm25pResource -> Arbiter;
  MainC.SoftwareInit -> Arbiter;

  components Stm25pSpiC as SpiC;
  SectorP.SpiResource -> SpiC;
  SectorP.Spi -> SpiC;
  MainC.SoftwareInit -> SpiC;

  components LedsC as Leds;
  SectorP.Leds -> Leds;

}

