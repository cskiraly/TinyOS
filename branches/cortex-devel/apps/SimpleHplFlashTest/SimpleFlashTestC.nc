/* $Id$
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
module SimpleFlashTestC {
  uses {
    interface Boot;
    interface Leds;
    interface HplAt45db;
    interface BusyWait<TMicro, uint16_t>;
    interface Timer<TMilli>;
  }
}
implementation {
  #define DATA_SIZE 50 
  uint8_t data[DATA_SIZE];
  uint8_t numIters = 10;
  uint16_t page2modify = 0;
  uint16_t offset2modify = 0;

  int val = 0;
  void beginTest() {
    int i;
    call Leds.led1Off();
    call Leds.led0Toggle();
    for(i=0; i<DATA_SIZE; i++, val++)
      data[i] = val;
    call HplAt45db.erase(AT45_C_ERASE_PAGE, page2modify);
  }
  event void Boot.booted() {
    beginTest();
  }
  event void Timer.fired() {
//    page2modify++;
    if(--numIters > 0)
      beginTest();
  }
  event void HplAt45db.eraseDone() {
    call BusyWait.wait(32768);
    call HplAt45db.write(AT45_C_WRITE_BUFFER1, 0, offset2modify, data, DATA_SIZE);
  }
  event void HplAt45db.writeDone() {
    call BusyWait.wait(32768);
    call HplAt45db.flush(AT45_C_FLUSH_BUFFER1, page2modify);
  }
  event void HplAt45db.flushDone() {
    int i;
    for(i=0; i<DATA_SIZE; i++)
      data[i] = 0;
    call BusyWait.wait(32768);
    call HplAt45db.fill(AT45_C_FILL_BUFFER1, page2modify);
  }  
  event void HplAt45db.fillDone() {
    call BusyWait.wait(32768);
    call HplAt45db.readBuffer(AT45_C_READ_BUFFER1, offset2modify, data, DATA_SIZE);
  }
  event void HplAt45db.readDone() {
    int i, j;
    for(i=0, j=val-DATA_SIZE; i<DATA_SIZE; i++, j++) {
      if(data[i] != j)
        call Leds.led1On();
    }
    call Timer.startOneShot(1000);
  }  
  event void HplAt45db.waitIdleDone() {}
  event void HplAt45db.waitCompareDone(bool compareOk) {}
  event void HplAt45db.compareDone() {}
  event void HplAt45db.crcDone(uint16_t computedCrc) {}
}
