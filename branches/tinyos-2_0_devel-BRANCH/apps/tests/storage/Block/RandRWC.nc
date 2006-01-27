/* $Id: RandRWC.nc,v 1.1.2.6 2006-01-27 21:39:14 jwhui Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Block storage test application. Does a pattern of random reads and
 * writes, based on mote id. See README.txt for more details.
 *
 * @author David Gay
 */
/*
  address & 3:
  0, 2: r
  1: w
  3: r&w
*/
module RandRWC {
  uses {
    interface Boot;
    interface Leds;
    interface BlockRead;
    interface BlockWrite;
  }
}
implementation {
  enum {
    S_ERASE,
    S_WRITE,
    S_COMMIT,
    S_VERIFY,
    S_READ
  } state;

  enum {
    SIZE = 1024L * 256,
    NWRITES = SIZE / 4096,
  };

  uint16_t shiftReg;
  uint16_t initSeed;
  uint16_t mask;

  /* Return the next 16 bit random number */
  uint16_t rand() {
    bool endbit;
    uint16_t tmpShiftReg;

    tmpShiftReg = shiftReg;
    endbit = ((tmpShiftReg & 0x8000) != 0);
    tmpShiftReg <<= 1;
    if (endbit) 
      tmpShiftReg ^= 0x100b;
    tmpShiftReg++;
    shiftReg = tmpShiftReg;
    tmpShiftReg = tmpShiftReg ^ mask;

    return tmpShiftReg;
  }

  void resetSeed() {
    shiftReg = 119 * 119 * ((TOS_LOCAL_ADDRESS >> 2) + 1);
    initSeed = shiftReg;
    mask = 137 * 29 * ((TOS_LOCAL_ADDRESS >> 2) + 1);
  }
  
  uint8_t data[512], rdata[512];
  int count;
  uint32_t addr, len;
  uint16_t offset;

  bool scheck(error_t r) __attribute__((noinline)) {
    if (r != SUCCESS)
      call Leds.led0On();
    return r == SUCCESS;
  }

  bool rcheck(error_t r) {
    if (r != SUCCESS)
      call Leds.led0On();
    return r == SUCCESS;
  }

  bool bcheck(bool b) {
    if (!b)
      call Leds.led0On();
    return b;
  }

  void setParameters() {
    addr = (uint32_t)count << 12 | (rand() >> 6);
    len = rand() >> 7;
    if (addr + len > SIZE)
      addr = SIZE - len;
    offset = rand() >> 8;
    if (offset + len > sizeof data)
      offset = sizeof data - len;
  }

  event void Boot.booted() {
    int i;

    resetSeed();
    for (i = 0; i < sizeof data; i++)
      data[i++] = rand() >> 8;

    if (TOS_LOCAL_ADDRESS & 1)
      {
	state = S_ERASE;
	rcheck(call BlockWrite.erase());
      }
    else
      {
	state = S_VERIFY;
	rcheck(call BlockRead.verify());
      }
  }

  void nextRead() {
    if (++count == NWRITES)
      {
	call Leds.led1On();
      }
    else
      {
	setParameters();
	rcheck(call BlockRead.read(addr, rdata, len));
      }
  }

  void nextWrite() {
    if (++count == NWRITES)
      {
	call Leds.led2Toggle();
	state = S_COMMIT;
	rcheck(call BlockWrite.commit());
      }
    else
      {
	setParameters();
	rcheck(call BlockWrite.write(addr, data + offset, len));
      }
  }

  event void BlockWrite.writeDone(storage_addr_t x, void* buf, storage_len_t y, error_t result) {
    if (scheck(result))
      nextWrite();
  }

  event void BlockWrite.eraseDone(error_t result) {
    if (scheck(result))
      {
	call Leds.led2Toggle();
	state = S_WRITE;
	count = 0;
	resetSeed();
	nextWrite();
      }
  }

  event void BlockWrite.commitDone(error_t result) {
    if (scheck(result))
      {
	if (TOS_LOCAL_ADDRESS & 2)
	  {
	    call Leds.led2Toggle();
	    state = S_VERIFY;
	    rcheck(call BlockRead.verify());
	  }
	else
	  call Leds.led1On();
      }
  }

  event void BlockRead.readDone(storage_addr_t x, void* buf, storage_len_t rlen, error_t result) __attribute__((noinline)) {
    if (scheck(result) && bcheck(x == addr && rlen == len && buf == rdata &&
				 memcmp(data + offset, rdata, rlen) == 0))
      nextRead();
  }

  event void BlockRead.verifyDone(error_t result) {
    if (scheck(result))
      {
	call Leds.led2Toggle();
	state = S_READ;
	count = 0;
	resetSeed();
	nextRead();
      }
  }

  event void BlockRead.computeCrcDone(storage_addr_t x, storage_len_t y, uint16_t z, error_t result) {
  }
}
