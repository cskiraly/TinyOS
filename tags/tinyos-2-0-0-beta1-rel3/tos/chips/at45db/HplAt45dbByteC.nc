/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Generic byte-at-a-time implementation of the AT45DB HPL.
 * 
 * Each platform must provide its own HPL implementation for its AT45DB
 * flash chip. To simplify this task, this component can easily be used to
 * build an AT45DB HPL by connecting it to a byte-at-a-time SPI interface,
 * and an HplAt45dbByte interface.
 *
 * @author David Gay
 */

generic module HplAt45dbByteC() {
  provides interface HplAt45db;
  uses {
    interface SpiByte as FlashSpi;
    interface HplAt45dbByte;
  }
}
implementation 
{
  enum {
    P_IDLE,
    P_SEND_CMD, 
    P_READ,
    P_READ_CRC,
    P_WRITE,
    P_WAIT_IDLE,
    P_WAIT_COMPARE,
    P_WAIT_COMPARE_OK,
    P_FILL,
    P_FLUSH,
    P_COMPARE,
    P_ERASE
  };
  uint8_t status = P_IDLE;
  uint16_t computedCrc;

  task void complete() {
    uint8_t s = status;

    status = P_IDLE;
    switch (s)
      {
      default: break;
      case P_READ_CRC:
	signal HplAt45db.crcDone(computedCrc);
	break;
      case P_FILL:
	signal HplAt45db.fillDone();
	break;
      case P_FLUSH:
	signal HplAt45db.flushDone();
	break;
      case P_COMPARE:
	signal HplAt45db.compareDone();
	break;
      case P_ERASE:
	signal HplAt45db.eraseDone();
	break;
      case P_READ:
	signal HplAt45db.readDone();
	break;
      case P_WRITE:
	signal HplAt45db.writeDone();
	break;
      }
  }

  event void HplAt45dbByte.idle() {
    if (status == P_WAIT_COMPARE)
      {
	bool cstatus = call HplAt45dbByte.getCompareStatus();
	call HplAt45dbByte.deselect();
	signal HplAt45db.waitCompareDone(cstatus);
      }
    else
      {
	call HplAt45dbByte.deselect();
	signal HplAt45db.waitIdleDone();
      }
  }

  void requestFlashStatus() {
    uint8_t dummy;

    call HplAt45dbByte.select();
    call FlashSpi.write(AT45_C_REQ_STATUS, &dummy);
    call HplAt45dbByte.waitIdle();
  }

  command void HplAt45db.waitIdle() {
    status = P_WAIT_IDLE;
    requestFlashStatus();
  }

  command void HplAt45db.waitCompare() {
    status = P_WAIT_COMPARE;
    requestFlashStatus();
  }


  void execCommand(uint8_t op, uint8_t reqCmd, uint8_t dontCare,
		   at45page_t page, at45pageoffset_t offset,
		   uint8_t *data, at45pageoffset_t dataCount, uint16_t crc) {
    uint8_t cmd[4];
    uint8_t in = 0, out = 0;
    uint8_t *ptr;
    at45pageoffset_t count;
    uint8_t lphase = P_SEND_CMD;

    status = op;

    /* For a 3% speedup, we could use labels and goto *.
       But: very gcc-specific. Also, need to do
              asm ("ijmp" : : "z" (state))
	    instead of goto *state
    */

    // page (2 bytes) and highest bit of offset
    cmd[0] = reqCmd;
    cmd[1] = page >> 7;
    cmd[2] = page << 1 | offset >> 8;
    cmd[3] = offset; // low-order 8 bits
    ptr = cmd;
    count = 4 + dontCare;

    call HplAt45dbByte.select();

    for (;;)
      {
	if (lphase == P_READ_CRC)
	  {
	    crc = crcByte(crc, in);

	    --count;
	    if (!count)
	      {
		computedCrc = crc;
		break;
	      }
	  }
	else if (lphase == P_SEND_CMD)
	  { 
	    out = *ptr++;
	    count--;
	    if (!count)
	      {
		lphase = op;
		ptr = data;
		count = dataCount;
	      }
	  }
	else if (lphase == P_READ)
	  {
	    *ptr++ = in;
	    --count;
	    if (!count)
	      break;
	  }
	else if (lphase == P_WRITE)
	  {
	    if (!count)
	      break;

	    out = *ptr++;
	    --count;
	  }
	else /* P_COMMAND */
	  break;
	
	call FlashSpi.write(out, &in);
      }

    call HplAt45dbByte.deselect();
    post complete();
  }

  command void HplAt45db.fill(uint8_t cmd, at45page_t page) {
    execCommand(P_FILL, cmd, 0, page, 0, NULL, 0, 0);
  }

  command void HplAt45db.flush(uint8_t cmd, at45page_t page) {
    execCommand(P_FLUSH, cmd, 0, page, 0, NULL, 0, 0);
  }

  command void HplAt45db.compare(uint8_t cmd, at45page_t page) {
    execCommand(P_COMPARE, cmd, 0, page, 0, NULL, 0, 0);
  }

  command void HplAt45db.erase(uint8_t cmd, at45page_t page) {
    execCommand(P_ERASE, cmd, 0, page, 0, NULL, 0, 0);
  }

  command void HplAt45db.read(uint8_t cmd,
				  at45page_t page, at45pageoffset_t offset,
				  uint8_t *data, at45pageoffset_t count) {
    execCommand(P_READ, cmd, 2, page, offset, data, count, 0);
  }

  command void HplAt45db.crc(uint8_t cmd,
				 at45page_t page, at45pageoffset_t offset,
				 at45pageoffset_t count,
				 uint16_t baseCrc) {
    execCommand(P_READ_CRC, cmd, 2, page, offset, NULL, count, baseCrc);
  }

  command void HplAt45db.write(uint8_t cmd,
				   at45page_t page, at45pageoffset_t offset,
				   uint8_t *data, at45pageoffset_t count) {
    execCommand(P_WRITE, cmd, 0, page, offset, data, count, 0);
  }
}
