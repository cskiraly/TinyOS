module HPLAT45DBByte {
  provides interface HPLAT45DB;
  uses {
    interface SlavePin as FlashSelect;
    interface FastSPI as FlashSPI;
    interface Resource as FlashIdle;
    command bool getCompareStatus();
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

  event result_t FlashSelect.notifyHigh() {
    uint8_t s = status;

    status = P_IDLE;
    switch (s)
      {
      case P_IDLE: break;
      case P_WAIT_IDLE:
	signal HPLAT45DB.waitIdleDone();
	break;
      case P_WAIT_COMPARE:
	signal HPLAT45DB.waitCompareDone(FALSE);
	break;
      case P_WAIT_COMPARE_OK:
	signal HPLAT45DB.waitCompareDone(TRUE);
	break;
      case P_READ_CRC:
	signal HPLAT45DB.crcDone(computedCrc);
	break;
      case P_FILL:
	signal HPLAT45DB.fillDone();
	break;
      case P_FLUSH:
	signal HPLAT45DB.flushDone();
	break;
      case P_COMPARE:
	signal HPLAT45DB.compareDone();
	break;
      case P_ERASE:
	signal HPLAT45DB.eraseDone();
	break;
      case P_READ:
	signal HPLAT45DB.readDone();
	break;
      case P_WRITE:
	signal HPLAT45DB.writeDone();
	break;
      }
    return SUCCESS;
  }

  event result_t FlashIdle.available() {
    if (status == P_WAIT_COMPARE && call getCompareStatus())
      status = P_WAIT_COMPARE_OK;
    call FlashSelect.high(TRUE);
    return SUCCESS;
  }

  void requestFlashStatus() {
    call FlashSelect.low();
    call FlashSPI.txByte(AT45_C_REQ_STATUS);
    if (call FlashIdle.wait() == FAIL) // already done
      signal FlashIdle.available();
  }

  command result_t HPLAT45DB.waitIdle() {
    status = P_WAIT_IDLE;
    requestFlashStatus();
    return SUCCESS;
  }

  command result_t HPLAT45DB.waitCompare() {
    status = P_WAIT_COMPARE;
    requestFlashStatus();
    return SUCCESS;
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

    call FlashSelect.low();

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
	
	in = call FlashSPI.txByte(out);
      }

    call FlashSelect.high(TRUE);
  }

  command result_t HPLAT45DB.fill(uint8_t cmd, at45page_t page) {
    execCommand(P_FILL, cmd, 0, page, 0, NULL, 0, 0);
    return SUCCESS;
  }

  command result_t HPLAT45DB.flush(uint8_t cmd, at45page_t page) {
    execCommand(P_FLUSH, cmd, 0, page, 0, NULL, 0, 0);
    return SUCCESS;
  }

  command result_t HPLAT45DB.compare(uint8_t cmd, at45page_t page) {
    execCommand(P_COMPARE, cmd, 0, page, 0, NULL, 0, 0);
    return SUCCESS;
  }

  command result_t HPLAT45DB.erase(uint8_t cmd, at45page_t page) {
    execCommand(P_ERASE, cmd, 0, page, 0, NULL, 0, 0);
    return SUCCESS;
  }

  command result_t HPLAT45DB.read(uint8_t cmd,
				  at45page_t page, at45pageoffset_t offset,
				  uint8_t *data, at45pageoffset_t count) {
    execCommand(P_READ, cmd, 2, page, offset, data, count, 0);
    return SUCCESS;
  }

  command result_t HPLAT45DB.crc(uint8_t cmd,
				 at45page_t page, at45pageoffset_t offset,
				 at45pageoffset_t count,
				 uint16_t baseCrc) {
    execCommand(P_READ_CRC, cmd, 2, page, offset, NULL, count, baseCrc);
    return SUCCESS;
  }

  command result_t HPLAT45DB.write(uint8_t cmd,
				   at45page_t page, at45pageoffset_t offset,
				   uint8_t *data, at45pageoffset_t count) {
    execCommand(P_WRITE, cmd, 0, page, offset, data, count, 0);
    return SUCCESS;
  }
}
