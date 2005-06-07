// $Id: HALSTM25PM.nc,v 1.1.2.2 2005-06-07 20:05:35 jwhui Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
    interface Timer;
  }
}

implementation {

  enum {
    S_POWEROFF = 0xfe,  // deep power-down state
    S_POWERON  = 0xff,  // awake state, no command in progress
  };

  volume_t curVolume;
  stm25p_sig_t signature;
  uint16_t crcScratch;
  uint8_t curCmd;

  void sendCmd(uint8_t cmd, stm25p_addr_t addr, void* data, stm25p_addr_t len);

  command result_t StdControl.init() {
    curCmd = S_POWEROFF;
    signature = STM25P_INVALID_SIG;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  void signalDone() {

    uint8_t tmpCmd = curCmd;
    curCmd = S_POWERON;

    call Timer.start(TIMER_ONE_SHOT, STM25P_POWEROFF_DELAY);

    switch(tmpCmd) {
    case STM25P_PP: signal HALSTM25P.pageProgramDone[curVolume](); break;
    case STM25P_SE: signal HALSTM25P.sectorEraseDone[curVolume](); break;
    case STM25P_BE: signal HALSTM25P.bulkEraseDone[curVolume](); break;
    case STM25P_WRSR: signal HALSTM25P.writeSRDone[curVolume](); break;
    }

  }

  bool isWriting() {
    uint8_t status;
    if (call HPLSTM25P.getBus() == FAIL)
      return TRUE;
    sendCmd(STM25P_RDSR, 0, &status, sizeof(status));
    call HPLSTM25P.releaseBus();
    return !!(status & 0x1);
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

  event result_t Timer.fired() {

    if (curCmd == S_POWERON)
      powerOff();
    else if (isWriting())
      call Timer.start(TIMER_ONE_SHOT, 1);
    else
      signalDone();

    return SUCCESS;

  }

  void sendCmd(uint8_t cmd, stm25p_addr_t addr, void* data, stm25p_addr_t len) {

    uint8_t cmdBytes[2*STM25P_ADDR_SIZE + 1];
    uint8_t i;

    // begin command
    call HPLSTM25P.beginCmd();
    
    cmdBytes[0] = STM25P_CMDS[cmd].cmd;

    // command, address and dummy bytes
    for ( i = 0; i < STM25P_ADDR_SIZE; i++ )
      cmdBytes[i+1] = (addr >> ((STM25P_ADDR_SIZE-1-i)*8)) & 0xff;
    call HPLSTM25P.txBuf(cmdBytes, (STM25P_CMD_SIZE +
				    STM25P_CMDS[cmd].address +
				    STM25P_CMDS[cmd].dummy) );

    // data
    if (STM25P_CMDS[cmd].receive)
      call HPLSTM25P.rxBuf(data, len, &crcScratch);
    else if (STM25P_CMDS[cmd].transmit)
      call HPLSTM25P.txBuf(data, len);

    // end command
    call HPLSTM25P.endCmd();

  }

  result_t newRequest(uint8_t cmd, volume_t volume, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {

    if (curCmd != S_POWERON && curCmd != S_POWEROFF)
      return FAIL;
    
    if (call HPLSTM25P.getBus() == FAIL)
      return FAIL;

    call Timer.stop();
    
    if (curCmd == S_POWEROFF)
      powerOn();

    curVolume = volume;
    curCmd = cmd;

    // enable writes
    if (STM25P_CMDS[curCmd].write)
      sendCmd(STM25P_WREN, 0, NULL, 0);

    // send command
    sendCmd(curCmd, addr, data, len);

    // post check for write done
    if (STM25P_CMDS[curCmd].write)
      call Timer.start(TIMER_ONE_SHOT, 1);
    else {
      curCmd = S_POWERON;
      call Timer.start(TIMER_ONE_SHOT, STM25P_POWEROFF_DELAY);
    }

    call HPLSTM25P.releaseBus();

    return SUCCESS;

  }

  command result_t HALSTM25P.read[volume_t volume](stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return newRequest(STM25P_READ, volume, addr, data, len);
  }

  command result_t HALSTM25P.pageProgram[volume_t volume](stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return newRequest(STM25P_PP, volume, addr, data, len);
  }

  command result_t HALSTM25P.sectorErase[volume_t volume](stm25p_addr_t addr) {
    return newRequest(STM25P_SE, volume, addr, NULL, 0);
  }

  command result_t HALSTM25P.bulkErase[volume_t volume]() {
    return newRequest(STM25P_BE, volume, 0, NULL, 0);
  }

  command result_t HALSTM25P.readSR[volume_t volume](void* value) {
    return newRequest(STM25P_RDSR, volume, 0, value, 1);
  }

  command result_t HALSTM25P.writeSR[volume_t volume](uint8_t value) {
    return newRequest(STM25P_WRSR, volume, 0, &value, 1);
  }

  command result_t HALSTM25P.computeCrc[volume_t volume](uint16_t* crcResult, uint16_t crc, stm25p_addr_t addr, stm25p_addr_t len) {
    result_t result;
    crcScratch = crc;
    result = newRequest(STM25P_CRC, volume, addr, NULL, len);
    *crcResult = crcScratch;
    return result;
  }

  command stm25p_sig_t HALSTM25P.getSignature[volume_t volume]() { 
    return signature; 
  }
  
  default event void HALSTM25P.pageProgramDone[volume_t volume]() {}
  default event void HALSTM25P.sectorEraseDone[volume_t volume]() {}
  default event void HALSTM25P.bulkEraseDone[volume_t volume]() {}
  default event void HALSTM25P.writeSRDone[volume_t volume]() {}

}
