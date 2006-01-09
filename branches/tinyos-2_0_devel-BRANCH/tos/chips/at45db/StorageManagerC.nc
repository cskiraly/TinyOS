configuration StorageManagerC {
  provides interface At45dbVolume[volume_t clientId];
}
implementation {
  components StorageManagerP, HalAt45dbC, MainC;

  At45dbVolume = StorageManagerP;
  MainC.SoftwareInit -> StorageManagerP;
  StorageManagerP.HalAt45db -> HalAt45dbC;
}
