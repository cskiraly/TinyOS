configuration StorageManagerC {
  provides {
    interface StdControl;
    interface Mount[volume_t volume];
    interface HALAT45DB[volume_t volume];
  }
}
implementation {
  components StorageManagerM, HALAT45DBC, HALAT45DBShare;

  StdControl = StorageManagerM;
  StdControl = HALAT45DBC;
  Mount = StorageManagerM;
  HALAT45DBC = HALAT45DBShare;

  HALAT45DBShare.ActualAT45 -> HALAT45DBC;
  HALAT45DBShare.AT45Remap -> StorageManagerM;
}
