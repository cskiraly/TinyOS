configuration WireBlockStorageP { }
implementation {
  components BlockStorageP, HalAt45dbC;

  BlockStorageP.HalAt45db -> HalAt45dbC;
}
