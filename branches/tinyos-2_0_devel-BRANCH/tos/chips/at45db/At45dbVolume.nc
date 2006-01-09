#include "HalAt45db.h"

interface At45dbVolume {
  command error_t mount(volume_id_t volid);
  event void mountDone(storage_result_t r, volume_id_t volid);

  /* Returns AT45_MAX_PAGES for invalid request (out of volume) */
  command at45page_t remap(at45page_t volumePage);

  command storage_addr_t volumeSize();
}
