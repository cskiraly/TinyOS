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
    interface At45db;
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
    call At45db.erase(page2modify, AT45_ERASE);
  }
  event void Boot.booted() {
    beginTest();
  }
  event void Timer.fired() {
//    page2modify++;
    if(--numIters > 0)
      beginTest();
  }
  event void At45db.eraseDone(error_t error) {
    if(error == SUCCESS) {
      call BusyWait.wait(32768);
      call At45db.write(page2modify, offset2modify, data, DATA_SIZE);
    }
  }
  event void At45db.writeDone(error_t error) {
    if(error == SUCCESS) {
      call BusyWait.wait(32768);
      call At45db.sync(page2modify);
    }
  }
  event void At45db.syncDone(error_t error) {
    int i;
    if(error == SUCCESS) {
      for(i=0; i<DATA_SIZE; i++)
        data[i] = 0;
      call BusyWait.wait(32768);
      call At45db.read(page2modify, offset2modify, data, DATA_SIZE);
    }
  }
  event void At45db.readDone(error_t error) {
    int i, j;
    if(error == SUCCESS) {
      for(i=0, j=val-DATA_SIZE; i<DATA_SIZE; i++, j++) {
        if(data[i] != j)
          call Leds.led1On();
      }
      call Timer.startOneShot(1000);
    }
  }  
  event void At45db.copyPageDone(error_t error) {
  }
  event void At45db.flushDone(error_t error) {
  }  
  event void At45db.computeCrcDone(error_t error, uint16_t crc) {
  }
}
