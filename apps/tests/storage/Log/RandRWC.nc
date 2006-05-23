/* $Id: RandRWC.nc,v 1.1.2.1 2006-05-23 21:57:20 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Log storage test application. Does a pattern of random reads and
 * writes, based on mote id. See README.txt for more details.
 *
 * @author David Gay
 */
/*
  address & 3:
  1: erase, write
  2: read
  3: write some more
*/
module RandRWC {
  uses {
    interface Boot;
    interface Leds;
    interface LogRead;
    interface LogWrite;
    interface AMSend;
    interface SplitControl as SerialControl;
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
    shiftReg = 119 * 119 * ((TOS_NODE_ID >> 2) + 1);
    initSeed = shiftReg;
    mask = 137 * 29 * ((TOS_NODE_ID >> 2) + 1);
  }
  
  uint8_t data[512], rdata[512];
  int count;
  uint32_t len;
  uint16_t offset;
  message_t reportmsg;

  void report(error_t e) {
    uint8_t *msg = call AMSend.getPayload(&reportmsg);

    msg[0] = e;
    if (call AMSend.send(AM_BROADCAST_ADDR, &reportmsg, 1) != SUCCESS)
      call Leds.led0On();
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS)
      call Leds.led0On();
  }

  void fail(error_t e) {
    call Leds.led0On();
    report(e);
  }

  bool scheck(error_t r) __attribute__((noinline)) {
    if (r != SUCCESS)
      fail(r);
    return r == SUCCESS;
  }

  bool bcheck(bool b) {
    if (!b)
      fail(FAIL);
    return b;
  }

  void setParameters() {
    len = rand() >> 7;
    offset = rand() >> 8;
    if (offset + len > sizeof data)
      offset = sizeof data - len;
  }

  event void Boot.booted() {
    call SerialControl.start();
  }

  event void SerialControl.stopDone(error_t e) { }

  void nextRead() {
    if (count == NWRITES)
      count = 0;
    if (count++ == 0)
      resetSeed();
    setParameters();
    scheck(call LogRead.read(rdata, len));
  }

  void nextWrite() {
    if (count++ == NWRITES)
      {
	state = S_COMMIT;
	scheck(call LogWrite.sync());
      }
    else
      {
	setParameters();
	scheck(call LogWrite.append(data + offset, len));
      }
  }

  event void LogWrite.appendDone(void *buf, storage_len_t y, error_t result) {
    if (scheck(result))
      nextWrite();
  }

  event void LogWrite.eraseDone(error_t result) {
    if (scheck(result))
      {
	call Leds.led2Toggle();
	state = S_WRITE;
	count = 0;
	resetSeed();
	nextWrite();
      }
  }

  event void LogWrite.syncDone(error_t result) {
    if (scheck(result))
      {
	call Leds.led1On();
	report(0x80);
      }
  }

  event void LogRead.readDone(void* buf, storage_len_t rlen, error_t result) __attribute__((noinline)) {
    if (result == ESIZE && rlen == 0 /*&& count == 1*/)
      {
	call Leds.led1On();
	report(0xc0);
	return;
      }
    if (scheck(result) && bcheck(rlen == len && buf == rdata && memcmp(data + offset, rdata, rlen) == 0))
      nextRead();
  }

  event void SerialControl.startDone(error_t e) {
    int i;

    if (e != SUCCESS)
      {
	call Leds.led0On();
	return;
      }

    resetSeed();
    for (i = 0; i < sizeof data; i++)
      data[i++] = rand() >> 8;

    switch (TOS_NODE_ID & 3)
      {
      case 1:
	state = S_ERASE;
	scheck(call LogWrite.erase());
	break;
      case 3:
	resetSeed();
	nextWrite();
	break;
      case 2:
	nextRead();
	break;
      }
  }

  event void LogRead.seekDone(error_t error) {
  }
}
