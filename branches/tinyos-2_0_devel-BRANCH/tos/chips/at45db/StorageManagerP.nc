#include "crc.h"
#include "StorageManager.h"

module StorageManagerP {
  provides {
    interface Init;
    interface At45dbVolume[volume_t clientId];
  }
  uses interface HalAt45db;
}
implementation {
  enum {
    NVOLUMES = uniqueCount(UQ_STORAGE_VOLUME)
  };

  struct volume_definition_header_t header;
  struct volume_definition_t volumes[NVOLUMES];

  enum {
    S_READY,
    S_MOUNTING
  };
  struct {
    bool validated : 1;
    bool invalid : 1;
    bool busy : 1;
    uint8_t state : 2;
  } f;

  uint8_t nextVolume;
  volume_t client;
  volume_id_t id;

  command error_t Init.init() {
    uint8_t i;

    for (i = 0; i < NVOLUMES; i++)
      volumes[i].id = INVALID_VOLUME_ID;

    return SUCCESS;
  }

  void mountComplete(storage_result_t r) {
    f.busy = FALSE;
    signal At45dbVolume.mountDone[client](r, id);
  }

  void checkNextVolume() {
    if (f.invalid || nextVolume == header.nvolumes)
      {
	volumes[client].id = INVALID_VOLUME_ID;
	mountComplete(STORAGE_FAIL);
      }
    else
      call HalAt45db.read(VOLUME_TABLE_PAGE, sizeof(struct volume_definition_header_t) +
			  nextVolume++ * sizeof(struct volume_definition_t),
			  &volumes[client], sizeof volumes[client]);
  }

  task void mountVolume() {
    if (!f.validated)
      call HalAt45db.read(VOLUME_TABLE_PAGE, 0, &header, sizeof header);
    else
      checkNextVolume();
  }

  command error_t At45dbVolume.mount[volume_t newClient](volume_id_t volid) {
    if (f.busy || volumes[newClient].id != INVALID_VOLUME_ID)
      return FAIL;

    f.busy = TRUE;
    client = newClient;
    id = volid;
    nextVolume = 0;
    post mountVolume();

    return SUCCESS;
  }

  command at45page_t At45dbVolume.remap[volume_t volume](at45page_t volumePage) {
    return volumePage + volumes[volume].start;
  }

  command storage_addr_t At45dbVolume.volumeSize[volume_t volume]() {
    return (storage_addr_t)volumes[volume].length << AT45_PAGE_SIZE_LOG2;
  }

  event void HalAt45db.writeDone(error_t result) {
  }

  event void HalAt45db.eraseDone(error_t result) {
  }

  event void HalAt45db.syncDone(error_t result) {
  }

  event void HalAt45db.flushDone(error_t result) {
  }

  event void HalAt45db.readDone(error_t result) {
    if (!f.busy)
      return;

    if (!f.validated)
      {
	size_t nvOffset = offsetof(struct volume_definition_header_t, nvolumes);
	size_t n = header.nvolumes * sizeof *volumes +
	  sizeof(struct volume_definition_header_t) - nvOffset;

	call HalAt45db.computeCrc(VOLUME_TABLE_PAGE, nvOffset, n, 0);
      }
    else
      {
	if (volumes[client].id == id)
	  mountComplete(STORAGE_OK);
	else
	  checkNextVolume();
      }
  }

  event void HalAt45db.computeCrcDone(error_t result, uint16_t crc) {
    if (!f.busy)
      return;

    f.validated = TRUE;
    f.invalid = crc != header.crc;
    checkNextVolume();
  }

  default event void At45dbVolume.mountDone[blockstorage_t bid](storage_result_t result, volume_id_t volid) { }
}
