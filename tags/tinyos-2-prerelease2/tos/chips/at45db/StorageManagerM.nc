module StorageManagerM {
  provides {
    interface StdControl;
    interface Mount[volume_t volume];
    interface AT45Remap[volume_t volume];
  }
}
implementation {
  volume_t client;
  volume_id_t id;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void mounted() {
    signal Mount.mountDone[client](STORAGE_OK, id);
  }

  command result_t Mount.mount[volume_t v](volume_id_t i) {
    client = v;
    id = i;
    post mounted();
    return SUCCESS;
  }

  command at45page_t AT45Remap.remap[volume_t volume](volume_t volume, at45page_t volumePage) {
    if (volume == 0)
      return volumePage;
    else
      return volumePage + 1024;
  }
}
