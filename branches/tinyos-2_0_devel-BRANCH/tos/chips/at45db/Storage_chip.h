// $Id: Storage_chip.h,v 1.1.2.4 2006-05-23 21:57:04 idgay Exp $

#ifndef STORAGE_CHIP_H
#define STORAGE_CHIP_H

#include "At45db.h"

#define UQ_BLOCK_STORAGE "BlockStorageP.BlockRead"
typedef uint8_t blockstorage_t;

#define UQ_LOG_STORAGE "LogStorageP.LogRead"
typedef uint8_t logstorage_t;

#endif
