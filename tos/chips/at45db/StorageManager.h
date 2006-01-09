#ifndef STORAGE_MANAGER_H
#define STORAGE_MANAGER_H

struct volume_definition_header_t
{
  uint16_t crc;
  uint8_t nvolumes;
};

struct volume_definition_t
{
  volume_id_t id;
  at45page_t start, length;
};

enum {
  INVALID_VOLUME_ID = 0,
  VOLUME_TABLE_SIZE = AT45_PAGE_SIZE,
  VOLUME_TABLE_PAGE = AT45_MAX_PAGES - 1,
  MAX_VOLUMES = (VOLUME_TABLE_SIZE - sizeof(struct volume_definition_header_t)) / sizeof(struct volume_definition_t)
};

#endif
