/*
* Copyright (c) 2004, Technische Universitaet Berlin
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* - Redistributions of source code must retain the above copyright notice,
*   this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the distribution.
* - Neither the name of the Technische Universitaet Berlin nor the names
*   of its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* - Revision -------------------------------------------------------------
* $Revision: 1.1.2.5 $
* $Date: 2006-02-01 17:44:18 $
* ========================================================================
*/

/**
* BasicMac module
*
* @author Kevin Klues <klues@tkn.tu-berlin.de>
*/

module BasicMacP {
  provides {
    interface Init;
    interface SplitControl;
    interface RadioByteComm;
    interface PhyPacketTx;
    interface PhyPacketRx;
  }
  uses {
    interface Tda5250Control;
    interface SplitControl as RadioSplitControl;
    interface Alarm<TMilli, uint32_t> as RxTimeoutTimer;
    interface RadioByteComm as Tda5250RadioByteComm;
    interface PhyPacketTx as Tda5250PhyPacketTx;
    interface PhyPacketRx as Tda5250PhyPacketRx;
  }
}
implementation
{
  /**************** Module Global Variables  *****************/
  bool txBusy, rxBusy;
  bool started;

  task void StartDone() {
    atomic started = TRUE;
    signal SplitControl.startDone(SUCCESS);
  }

  /**************** Radio Init  *****************/
  command error_t Init.init(){
    atomic {
      txBusy = FALSE;
      rxBusy = FALSE;
    }
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    return call RadioSplitControl.start();
  }

  /**************** Radio Stop  *****************/
  command error_t SplitControl.stop(){
    call RxTimeoutTimer.stop();
    call RadioSplitControl.stop();
    return SUCCESS;
  }

  event void RadioSplitControl.startDone(error_t error) {
    if(error != SUCCESS)
      signal SplitControl.startDone(error);
    else call Tda5250Control.RxMode();
  }

  event void RadioSplitControl.stopDone(error_t error) {
    atomic started = FALSE;
    signal SplitControl.stopDone(error);
  }

  async command void PhyPacketTx.sendHeader() {
    bool busy = FALSE;
    atomic {
      if(txBusy == TRUE || rxBusy == TRUE)
        busy = TRUE;
      else {
        txBusy = TRUE;
      }
    }
    if(busy == FALSE) {
      if(call Tda5250Control.TxMode() == SUCCESS)
        return;
      atomic txBusy = FALSE;
      signal PhyPacketTx.sendHeaderDone(FAIL);
    }
    else {
      atomic txBusy = FALSE;
      signal PhyPacketTx.sendHeaderDone(EBUSY);
    }
  }

  async command void RadioByteComm.txByte(uint8_t data) {
    call Tda5250RadioByteComm.txByte(data);
  }

  async command bool RadioByteComm.isTxDone() {
    return call Tda5250RadioByteComm.isTxDone();
  }

  async command void PhyPacketTx.sendFooter() {
    call Tda5250PhyPacketTx.sendFooter();
  }

  /**************** Radio Recv ****************/
  async command void PhyPacketRx.recvHeader() {
    atomic rxBusy = FALSE;
    call Tda5250PhyPacketRx.recvHeader();
  }

  async command void PhyPacketRx.recvFooter() {
    call Tda5250PhyPacketRx.recvFooter();
  }

  async command error_t PhyPacketTx.cancel() {
    return call Tda5250PhyPacketTx.cancel();
  }

  async event void Tda5250PhyPacketTx.sendHeaderDone(error_t error) {
    if(error != SUCCESS)
      call Tda5250Control.RxMode();
    signal PhyPacketTx.sendHeaderDone(error);
  }

  /**************** Rx Done ****************/
  async event void Tda5250RadioByteComm.txByteReady(error_t error) {
    if(error != SUCCESS)
      call Tda5250Control.RxMode();
    signal RadioByteComm.txByteReady(error);
  }

  async event void Tda5250PhyPacketTx.sendFooterDone(error_t error) {
    call Tda5250Control.RxMode();
    signal PhyPacketTx.sendFooterDone(error);
  }

  async event void Tda5250PhyPacketRx.recvHeaderDone() {
    atomic rxBusy = TRUE;
    //call RxTimeoutTimer.start((((TOSH_DATA_LENGTH+2)*100)/(384)+1));
    call RxTimeoutTimer.start((TOSH_DATA_LENGTH+2)<<2);
    signal PhyPacketRx.recvHeaderDone();
  }

  async event void RxTimeoutTimer.fired() {
    atomic {
      if(rxBusy == FALSE)
        return;
      atomic rxBusy = FALSE;
    }
    call Tda5250PhyPacketRx.recvHeader();
  }

  /**************** Rx Done ****************/
  async event void Tda5250RadioByteComm.rxByteReady(uint8_t data) {
    signal RadioByteComm.rxByteReady(data);
  }

  async event void Tda5250PhyPacketRx.recvFooterDone(bool error) {
    call RxTimeoutTimer.stop();
    signal PhyPacketRx.recvFooterDone(error);
  }

  async event void Tda5250Control.TxModeDone(){
    call Tda5250PhyPacketTx.sendHeader();
  }
  async event void Tda5250Control.TimerModeDone(){
  }
  async event void Tda5250Control.SelfPollingModeDone(){
  }
  async event void Tda5250Control.RxModeDone(){
    bool state;
    atomic {
      txBusy = FALSE;
      rxBusy = FALSE;
      state = started;
    }
    call Tda5250PhyPacketRx.recvHeader();
    if(state == FALSE)
      post StartDone();
  }
  async event void Tda5250Control.SleepModeDone(){
  }
  async event void Tda5250Control.CCAModeDone(){
  }
  async event void Tda5250Control.PWDDDInterrupt() {
  }
}
