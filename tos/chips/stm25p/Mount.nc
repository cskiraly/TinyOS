
includes Storage;

interface Mount {
  command result_t mount(volume_id_t id);
  event void mountDone(storage_result_t result, volume_id_t id);
}
