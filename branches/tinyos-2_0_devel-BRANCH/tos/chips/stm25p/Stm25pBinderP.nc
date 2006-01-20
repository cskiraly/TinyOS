
generic module Stm25pBinderP( volume_id_t volume ) {

  uses interface Stm25pVolume as Volume;

}

implementation {

  async event volume_id_t Volume.getVolumeId() {
    return volume;
  }

}

