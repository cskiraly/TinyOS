// $Id: HALSTM25PM.nc,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module HALSTM25PM {
  provides {
    interface StdControl;
    interface HALSTM25P[volume_t volume];
  }
  uses {
    interface HPLSTM25P;
    interface Leds;
    interface StorageRemap[volume_t volume];
  }
}

implementation {
  
  enum {
    S_POWEROFF, // deep power-down state
    S_POWERON,  // awake state, no command in progress
  };

  stm25p_sig_t signature;
  uint16_t     crc;
  uint8_t      curCmd;
  volume_t     curVolume;

  void sendCmd(uint8_t cmd, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len);

  command result_t StdControl.init() {
    curCmd = S_POWEROFF;
    signature = STM25P_INVALID_SIG;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  void signalDone(result_t result) {
    uint8_t tmpCmd = curCmd;
    curCmd = S_POWERON;

    switch(tmpCmd) {
    case STM25P_READ: signal HALSTM25P.readDone[curVolume](result); break;
    case STM25P_PP: signal HALSTM25P.pageProgramDone[curVolume](result); break;
    case STM25P_SE: signal HALSTM25P.sectorEraseDone[curVolume](result); break;
    case STM25P_BE: signal HALSTM25P.bulkEraseDone[curVolume](result); break;
    case STM25P_WRSR: signal HALSTM25P.writeSRDone[curVolume](result); break;
    case STM25P_CRC: signal HALSTM25P.computeCrcDone[curVolume](result, crc); break;
    }
  }

  task void signalSuccess() { signalDone(SUCCESS); }
  task void signalFail() { signalDone(FAIL); }

  void checkPost(bool result) {
    if (result == FALSE)
      signalDone(FAIL);
  }

  bool isWriting() {
    uint8_t status;
    if (call HPLSTM25P.getBus() == FAIL)
      return TRUE;
    sendCmd(STM25P_RDSR, 0, &status, sizeof(status));
    call HPLSTM25P.releaseBus();
    return (status & 0x1) ? TRUE : FALSE;
  }

  // probably better to use a timer since write operations can take on
  // the order of seconds to complete
  task void checkWriteDone() {
    if (isWriting()) {
      checkPost(post checkWriteDone());
      return;
    }
    signalDone(SUCCESS);
  }

  void sendCmd(uint8_t cmd, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {

    uint8_t addrBytes[STM25P_ADDR_SIZE];
    stm25p_addr_t i;

    // start command
    switch(cmd) {
    case STM25P_CRC: call HPLSTM25P.beginCmd(STM25P_READ); break;
    default: call HPLSTM25P.beginCmd(cmd); break;
    }
    
    // address
    switch(cmd) {
    case STM25P_READ: case STM25P_FAST_READ: case STM25P_PP: 
    case STM25P_SE: case STM25P_CRC:
      for ( i = 0; i < STM25P_ADDR_SIZE; i++ )
	addrBytes[i] = (addr >> ((STM25P_ADDR_SIZE-1-i)*8)) & 0xff;
      call HPLSTM25P.txBuf(addrBytes, STM25P_ADDR_SIZE);
      break;
    }

    // dummy bytes
    switch(cmd) {
    case STM25P_FAST_READ:
      call HPLSTM25P.txBuf(addrBytes, STM25P_FR_DUMMY_BYTES);
      break;
    case STM25P_RES:
      call HPLSTM25P.txBuf(addrBytes, STM25P_RES_DUMMY_BYTES);
      break;
    }

    // data
    switch(cmd) {
    case STM25P_RDSR: case STM25P_READ: case STM25P_FAST_READ: case STM25P_RES:
      call HPLSTM25P.rxBuf(data, len);
      break;
    case STM25P_WRSR: case STM25P_PP:
      call HPLSTM25P.txBuf(data, len);
      break;
    case STM25P_CRC:
      call HPLSTM25P.computeCrc(&crc, len);
      break;
    }

    // end command
    call HPLSTM25P.endCmd();

  }

  void powerOff() {
    sendCmd(STM25P_DP, 0, NULL, 0);
    curCmd = S_POWEROFF;
  }

  void powerOn() {
    sendCmd(STM25P_RES, 0, &signature, sizeof(signature));
    TOSH_uwait(2); // wait at least 1.8us to power on
    curCmd = S_POWERON;
  }

  result_t newRequest(uint8_t cmd, volume_t volume, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {

    // make sure flash is powered on
    if (curCmd == S_POWEROFF)
      powerOn();
    // make sure nothing else is in progress
    else if (curCmd != S_POWERON)
      return FAIL;
    // make sure we can get the bus
    else if (call HPLSTM25P.getBus() == FAIL)
      return FAIL;

    addr = call StorageRemap.physicalAddr[volume](addr);

    curVolume = volume;
    
    curCmd = cmd;
    crc = 0;
    
    // enable writes if needed
    if (curCmd == STM25P_WRSR || curCmd == STM25P_PP 
	|| curCmd == STM25P_SE || curCmd == STM25P_BE)
      sendCmd(STM25P_WREN, 0, NULL, 0);
    
    // send command
    sendCmd(curCmd, addr, data, len);

    call HPLSTM25P.releaseBus();

    // setup check for write done
    if (curCmd == STM25P_WRSR || curCmd == STM25P_PP 
	|| curCmd == STM25P_SE || curCmd == STM25P_BE)
      checkPost(post checkWriteDone());
    else
      checkPost(post signalSuccess());

    return SUCCESS;

  }

  command result_t HALSTM25P.read[volume_t volume](stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {
    return newRequest(STM25P_READ, volume, addr, data, len);
  }

  command result_t HALSTM25P.pageProgram[volume_t volume](stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {
    return newRequest(STM25P_PP, volume, addr, data, len);
  }

  command result_t HALSTM25P.sectorErase[volume_t volume](stm25p_addr_t addr) {
    return newRequest(STM25P_SE, volume, addr, NULL, 0);
  }

  command result_t HALSTM25P.bulkErase[volume_t volume]() {
    return newRequest(STM25P_BE, volume, 0, NULL, 0);
  }

  command result_t HALSTM25P.writeSR[volume_t volume](uint8_t value) {
    return newRequest(STM25P_WRSR, volume, 0, &value, 1);
  }

  command result_t HALSTM25P.computeCrc[volume_t volume](stm25p_addr_t addr, stm25p_addr_t len) {
    return newRequest(STM25P_CRC, volume, addr, NULL, len);
  }

  command stm25p_sig_t HALSTM25P.getSignature[volume_t volume]() { 
    return signature; 
  }
  
  default event void HALSTM25P.readDone[volume_t volume](result_t result) { ; }
  default event void HALSTM25P.pageProgramDone[volume_t volume](result_t result) { ; }
  default event void HALSTM25P.sectorEraseDone[volume_t volume](result_t result) { ; }
  default event void HALSTM25P.bulkEraseDone[volume_t volume](result_t result) { ; }
  default event void HALSTM25P.writeSRDone[volume_t volume](result_t result) { ; }
  default event void HALSTM25P.computeCrcDone[volume_t volume](result_t result, uint16_t crcResult) { ; }

}
