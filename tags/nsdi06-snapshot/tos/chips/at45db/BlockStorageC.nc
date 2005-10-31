// $Id: BlockStorageC.nc,v 1.1.2.1 2005-02-09 18:34:01 idgay Exp $
generic configuration BlockStorageC() {
  provides {
    interface Mount;
    interface BlockWrite;
    interface BlockRead;
  }
}
implementation {
  enum {
    BLOCK_ID = unique(UQ_BLOCK_STORAGE),
    VOLUME_ID = unique(UQ_STORAGE_VOLUME)
  };
    
  components BlockStorageM, StorageManagerC;

  Mount = BlockStorageM.Mount[BLOCK_ID];
  BlockWrite = BlockStorageM.BlockWrite[BLOCK_ID];
  BlockRead = BlockStorageM.BlockRead[BLOCK_ID];

  BlockStorageM.HALAT45DB[BLOCK_ID] -> StorageManagerC.HALAT45DB[VOLUME_ID];
  BlockStorageM.ActualMount[BLOCK_ID] -> StorageManagerC.Mount[VOLUME_ID];
}
