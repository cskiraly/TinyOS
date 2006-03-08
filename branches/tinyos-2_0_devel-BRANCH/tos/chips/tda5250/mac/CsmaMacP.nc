/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
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
 * - Description ---------------------------------------------------------
 * A Csma Mac
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "message.h"

module CsmaMacP {
    provides {
      interface Init;
      interface SplitControl;
      interface Send;
      interface Receive;
    }
    uses {
      interface StdControl as CcaStdControl;
      interface Send as PacketSend;
      interface Receive as PacketReceive;
      interface Packet;
        
      interface PhyPacketRx;
      //FIXME: RadioModes Interface
      interface Tda5250Control as RadioModes;  

      interface ChannelMonitor;
      interface ChannelMonitorControl;  
      interface ChannelMonitorData;

      interface Random;
        
      interface Timer<TMilli> as MinClearTimer;
      interface Timer<TMilli> as RxPacketTimer;
      interface Timer<TMilli> as BackoffTimer;
    }
}
implementation
{
    #define MACM_DEBUG
    /* milli second in jiffies */
    #define MSEC 33
    /* max. Packet duration in ms */
    #define RX_PACKET_TIME (TOSH_DATA_LENGTH+2)<<2
    /* define minislot time */
    #define MINISLOT_TIME 31
        
    #define RX_THRESHOLD 13 // SNR should be at least RX_THRESHOLD dB before RX attempt
    
    /**************** Module Global Variables  *****************/
    message_t* txBufPtr;
    uint8_t txLen;
    int16_t rssiValue;

    typedef enum {
      INIT,
      SW_CCA,          // switch to CCA
      CCA,             // clear channel assessment       
      SW_TX,           // switch to Tx mode
      TX_P,            // transmitting packet
      SW_RX,           // switch to receive
      RX,              // rx mode done, listening & waiting for packet
      RX_P,            // receive packet
    } macState_t;

    macState_t macState;

    typedef enum {
      MIN_CLEAR_TIMER = 1,
      RX_PACKET_TIMER = 2,
      BACKOFF_TIMER = 4,
    } timerPos_t;

    timerPos_t dirtyTimers;
    timerPos_t firedTimers;
    timerPos_t runningTimers;
    timerPos_t restartTimers;

    #ifdef MACM_DEBUG
    #define HISTORY_ENTRIES 40
    typedef struct {
      int index;
      macState_t state;
      int        place;
    } history_t;
    
    history_t history[HISTORY_ENTRIES];
    unsigned histIndex;
    void storeOldState(int p) {
      atomic {
        history[histIndex].index = histIndex;
        history[histIndex].state = macState;
        history[histIndex].place = p;
        histIndex++;
        if(histIndex >= HISTORY_ENTRIES) histIndex = 0;
      }
    }
    #else
    void storeOldState(int p) {};
    #endif


    /** the value in this variable denotes how often we have seen
     * the channel busy when trying to access it
    */
    uint8_t inBackoff;
    
    /* on and off times for preamble sampling mode in jiffies */
    uint16_t slotModulo;

    /* drop packet if we see the channel busy 
      MAX_TX_ATTEMPTS times in a row 
    */
    #define MAX_TX_ATTEMPTS 5
    
    /******** for atomic acks: allow  between packet and ACK ****/
    #define DIFS 1 // disabled, work around msp430 clock bug

    /****** Helper functions  ***********************/
    void signalFailure() {
#ifdef MACM_DEBUG
      atomic {
        for(;;) {
          ;
        }
      }
#endif
    }

    /****** Packet Helper Functions ******************/
    message_radio_metadata_t* getMetadata(message_t* amsg) {
      return (message_radio_metadata_t*)((uint8_t*)amsg->footer + sizeof(message_radio_footer_t));
    }
    
    /****** Timer Helper Functions ******************/
    void markTFlag(timerPos_t *which, timerPos_t pos) {
      (*which) |= pos;
    }
    void clearTFlag(timerPos_t *which, timerPos_t pos) {
      (*which) = (*which) & (~pos);
    }
    bool isTFlagSet(const timerPos_t *which, timerPos_t pos) {
      return (*which) & pos;
    }

    /* Radio Modes */
    void setCCAMode();
    void setRxMode();
    void setTxMode();
    
    /**************** Init ************************/
    command error_t Init.init(){
      atomic {
        txBufPtr = NULL;
        macState = INIT;
        inBackoff = 0;
        firedTimers = 0;
        dirtyTimers = 0;
        runningTimers = 0;
        slotModulo = 0x1F; 
#ifdef MACM_DEBUG
        histIndex = 0;
#endif
      }
      return SUCCESS;
    }

    /****************  SplitControl  *****************/
    command error_t SplitControl.start() {
      call CcaStdControl.start();
      setCCAMode();
      return SUCCESS;
    }

    task void StopDone() {
      call MinClearTimer.stop();
      call RxPacketTimer.stop();
      call BackoffTimer.stop();
      signal SplitControl.stopDone(SUCCESS); 
    }
    
    command error_t SplitControl.stop() {
      call CcaStdControl.stop();
      post StopDone();
      return SUCCESS;
    }

    /****** Async -> Sync Helper Tasks ****************/
    task void SendDoneFailTask();
    
    /****** Timer Helper tasks *****************************/

    task void StopMinClearTimerTask();
    task void StopRxPacketTimerTask();
    task void StopBackoffTimerTask();

    // cs = clear and maybe start, only start if start requested and in correct
    // mac state
    task void CSMinClearTimerTask()   {
      atomic {
        clearTFlag(&dirtyTimers, MIN_CLEAR_TIMER);
        if(isTFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
          if(macState == CCA) {
            call MinClearTimer.startOneShot(DIFS);
            clearTFlag(&restartTimers, MIN_CLEAR_TIMER);
            markTFlag(&runningTimers, MIN_CLEAR_TIMER);
          } else {
            clearTFlag(&restartTimers, MIN_CLEAR_TIMER);
          }
        }
      }
    };
    
    task void CSRxPacketTimerTask()    {
      atomic {
        clearTFlag(&dirtyTimers, RX_PACKET_TIMER);
        if(isTFlagSet(&restartTimers, RX_PACKET_TIMER)) {
          if(macState == RX_P) {
            call RxPacketTimer.startOneShot(RX_PACKET_TIME) ;
            clearTFlag(&restartTimers, RX_PACKET_TIMER);
            markTFlag(&runningTimers, RX_PACKET_TIMER);
          } else {
            clearTFlag(&restartTimers, RX_PACKET_TIMER);
          }
        }
      }
    }

    task void CSBackoffTimerTask() {
      int32_t slot;
      int32_t iB;
      uint16_t window;
      bool action = FALSE;
      atomic {
        iB = inBackoff;
        clearTFlag(&dirtyTimers, BACKOFF_TIMER);
        if(isTFlagSet(&restartTimers, BACKOFF_TIMER)) {
          action = TRUE;
        }
      }
      if(action) {
        window = 2 * iB;
        slot = call Random.rand16();
        slot %= window;
        ++slot;
        slot *= (MINISLOT_TIME); 
        slot += (call Random.rand16() & slotModulo);
        call BackoffTimer.startOneShot(slot);
        atomic {
          clearTFlag(&restartTimers, BACKOFF_TIMER);
          markTFlag(&runningTimers, BACKOFF_TIMER);
        }
      }
    }

    void csMinClearTimer(bool inAsync) {
      atomic {
        if(isTFlagSet(&runningTimers, MIN_CLEAR_TIMER)) {
          markTFlag(&dirtyTimers, MIN_CLEAR_TIMER);
          if(inAsync) {
            post StopMinClearTimerTask();
          } else {
            clearTFlag(&runningTimers, MIN_CLEAR_TIMER);
            call MinClearTimer.stop();
            post CSMinClearTimerTask();
          }
        } else if(isTFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
          post CSMinClearTimerTask();
        }
      }
    }
    task void StopMinClearTimerTask() { csMinClearTimer(FALSE); }
    void stopMinClearTimer(bool inAsync) {
      clearTFlag(&restartTimers, MIN_CLEAR_TIMER);
      csMinClearTimer(inAsync);
    }
    void restartMinClearTimer(bool inAsync) {
      markTFlag(&restartTimers, MIN_CLEAR_TIMER);
      csMinClearTimer(inAsync);
    }

    void csRxPacketTimer(bool inAsync) {
      atomic {
        if(isTFlagSet(&runningTimers, RX_PACKET_TIMER)) {
          markTFlag(&dirtyTimers, RX_PACKET_TIMER);
          if(inAsync) {
            post StopRxPacketTimerTask();
          } else {
            clearTFlag(&runningTimers, RX_PACKET_TIMER);
            call RxPacketTimer.stop();
            post CSRxPacketTimerTask();
          }
        }
        else if(isTFlagSet(&dirtyTimers, RX_PACKET_TIMER)) {
            // do nothing
        }
        else if(isTFlagSet(&restartTimers, RX_PACKET_TIMER)) {
          post CSRxPacketTimerTask();
        }
      }
    }
    task void StopRxPacketTimerTask() { csRxPacketTimer(FALSE); };
    void stopRxPacketTimer(bool inAsync) {
        clearTFlag(&restartTimers, RX_PACKET_TIMER);
        csRxPacketTimer(inAsync);
    };
    void restartRxPacketTimer(bool inAsync) {
      markTFlag(&restartTimers, RX_PACKET_TIMER);
      csRxPacketTimer(inAsync);
    };

    void csBackoffTimer(bool inAsync) {
      atomic {
        if(isTFlagSet(&runningTimers, BACKOFF_TIMER)) {
          markTFlag(&dirtyTimers, BACKOFF_TIMER);
          if(inAsync) {
            post StopBackoffTimerTask();
          } else {
            clearTFlag(&runningTimers, BACKOFF_TIMER);
            call BackoffTimer.stop();
            post CSBackoffTimerTask();
          }
        }
        else if(isTFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
            // do nothing
        }
        else if(isTFlagSet(&restartTimers, BACKOFF_TIMER)) {
          post CSBackoffTimerTask();
        }
      }
    }
    task void StopBackoffTimerTask() { csBackoffTimer(FALSE); };
    void stopBackoffTimer(bool inAsync) {
      clearTFlag(&restartTimers, BACKOFF_TIMER);
      csBackoffTimer(inAsync);
    };
    void restartBackoffTimer(bool inAsync) {
      markTFlag(&restartTimers, BACKOFF_TIMER);
      csBackoffTimer(inAsync);
    };
    /****** Secure switching of radio modes ***/
    task void CCAModeTask();
    task void SetRxModeTask();
    task void SetTxModeTask();

    void setCCAMode() {
      if(call RadioModes.CCAMode() == SUCCESS) {
        storeOldState(0);
      } else {
        post CCAModeTask();
      }
    }

    task void CCAModeTask() {
      macState_t ms;
      atomic ms = macState;
      if((ms == SW_CCA) || (ms == INIT)) setCCAMode();
    }

    void setRxMode() {
      if(call RadioModes.RxMode() == FAIL) {
        post SetRxModeTask();
      }
    }

    task void SetRxModeTask() {
      macState_t ms;
      atomic ms = macState;
      if(ms == SW_RX) setRxMode();
    }
    
    void setTxMode() {
      if(call RadioModes.TxMode() == FAIL) {
        post SetTxModeTask();
      }
    }

    task void SetTxModeTask() {
      macState_t ms;
      atomic ms = macState;
      if(ms == SW_TX) setTxMode();
    }
        
    
    async event void RadioModes.CCAModeDone() {
      atomic  {
        if(macState == SW_CCA)  {
          if(call ChannelMonitor.start() == SUCCESS) {
            clearTFlag(&firedTimers, MIN_CLEAR_TIMER);
            restartMinClearTimer(FALSE);
            storeOldState(2);
            macState = CCA;
          } else {
            storeOldState(3);
            setCCAMode();
          }
        }
        else if(macState == INIT) {
          storeOldState(6);
          if ( (call ChannelMonitorControl.updateNoiseFloor() == FAIL)  ) {
            setCCAMode(); 
          } 
        } else {
          storeOldState(7);
        }
      }
    }

    async event void RadioModes.RxModeDone() {
      atomic {
        if(macState == SW_RX) {
          storeOldState(9);
          macState = RX;
          call PhyPacketRx.recvHeader();
        }
        else {
          storeOldState(-9);
          signalFailure(); 
        }
      }
    }

    async event void RadioModes.TxModeDone() {
      error_t error = FAIL;
      atomic {
        if(macState == SW_TX) {
          storeOldState(10);
          macState = TX_P;
          clearTFlag(&firedTimers, MIN_CLEAR_TIMER);
          clearTFlag(&firedTimers, BACKOFF_TIMER);
          error = call PacketSend.send(txBufPtr, txLen);
          if( error != SUCCESS) {
            storeOldState(-65);
            post SendDoneFailTask();
          } else {
            storeOldState(65);
          }

        }
        else {
          storeOldState(-10);
          signalFailure(); 
        }
      }
    }
    
    
    /****** PacketSerializer events **********************/

    event message_t* PacketReceive.receive(message_t* msg, void* payload, uint8_t len) {
      atomic {
        storeOldState(12);
        stopRxPacketTimer(FALSE);
        if( isTFlagSet(&firedTimers, BACKOFF_TIMER) ) {
          macState = SW_CCA;
          setCCAMode();
        } else if (macState != INIT) {
          macState = RX;
          call PhyPacketRx.recvHeader();
        }
      }
      atomic {
        (getMetadata(msg))->strength = rssiValue;
      }
      signal Receive.receive(msg, payload, len);
      return msg;
    }


    event void PacketSend.sendDone(message_t* msg, error_t error) {
      atomic {
        if(macState == TX_P) { 
          storeOldState(13);
          stopBackoffTimer(FALSE);
          txBufPtr = NULL; 
          inBackoff = 0;
          macState = SW_RX;
          setRxMode();
        } else {
          storeOldState(-13);
          signalFailure();
        }
        signal Send.sendDone(msg, error);
      }
      
    }


    /****** MinClearTimer ******************************/
    event void MinClearTimer.fired() {
      atomic {
        if(isTFlagSet(&dirtyTimers, MIN_CLEAR_TIMER)) {
          storeOldState(17);
        } else {
          if(macState == CCA) {
            markTFlag(&firedTimers, MIN_CLEAR_TIMER);
            storeOldState(18);
          } else {
            storeOldState(-18);
            signalFailure();
          }
          clearTFlag(&runningTimers, MIN_CLEAR_TIMER);
        }
      }
    }

    /****** RxPacketTimer ******************************/
    event void RxPacketTimer.fired() {
      atomic {
        if(isTFlagSet(&dirtyTimers, RX_PACKET_TIMER)) {
          storeOldState(19);
        }
        else {
          if(macState == RX_P) {
            storeOldState(21);
            markTFlag(&firedTimers, RX_PACKET_TIMER);
            stopRxPacketTimer(FALSE);
            if( isTFlagSet(&firedTimers, BACKOFF_TIMER) ) {
              macState = SW_CCA;
              setCCAMode();
            } else {
              macState = RX;
              // reset PhyPacket state...    
              call PhyPacketRx.recvHeader();
            }
          } else {
            storeOldState(-21);
            signalFailure();
          }
          clearTFlag(&runningTimers, RX_PACKET_TIMER);
        }
      }
    }

    /****** BackoffTimer ******************************/

    event void BackoffTimer.fired() {
      macState_t ms = RX;
      atomic {
        if(isTFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
          storeOldState(23);
        }
        else {
          if ((macState == RX) || (macState == SW_RX)) {
            storeOldState(24);
            ms = SW_CCA;
          } else if (macState == INIT) {
            storeOldState(26);
            ms = INIT;
          } else {
            markTFlag(&firedTimers, BACKOFF_TIMER);
            storeOldState(27);
          }
          clearTFlag(&runningTimers, BACKOFF_TIMER);
        }
      }
      if(ms == INIT) {
        restartBackoffTimer(FALSE);
      } else if (ms == SW_CCA) {
        atomic macState = SW_CCA;
        setCCAMode();
      }
    }

    /****** Send / Receive *********************/
    task void SendDoneFailTask() {
      signal Send.sendDone((message_t*)txBufPtr, FAIL);
    }

    command error_t Send.send(message_t* msg, uint8_t len) {
      atomic {
        if(inBackoff == 0) {
          storeOldState(50);
          switch(macState) {
            //case SW_RX:
            case RX:
              macState = SW_CCA;
              setCCAMode();
            case RX_P:
              inBackoff = 1;
              txBufPtr = msg;
              txLen = len;
              restartBackoffTimer(TRUE);  
              return SUCCESS;
              break;
            default:
              return EBUSY;
              break;
          }
        } else {
          storeOldState(51);
        }
      }
      return EBUSY;
    }

    command void* Send.getPayload(message_t* msg) {
      return call PacketSend.getPayload(msg);
    }

    command uint8_t Send.maxPayloadLength() {
      return call PacketSend.maxPayloadLength();
    }

    command error_t Send.cancel(message_t* msg) {
      atomic {
        if (call PacketSend.cancel(msg)) {
          stopBackoffTimer(FALSE);
          stopMinClearTimer(FALSE);
          txBufPtr = 0;
          inBackoff = 0;
          macState = SW_RX;
          setRxMode();
          return SUCCESS;
        } else {
          return FAIL;
        }
      } 
    }

    command void* Receive.getPayload(message_t* msg, uint8_t* len) {
      return call PacketReceive.getPayload(msg, len);
    }

    command uint8_t Receive.payloadLength(message_t* msg) {
      return call PacketReceive.payloadLength(msg);
    }

    /******* PacketRx/Tx *******************************/
    async event void PhyPacketRx.recvHeaderDone() {
      macState_t ms = RX;
      atomic { ms = macState; }
      if(ms == RX) {
        storeOldState(4);
        call ChannelMonitor.rxSuccess();
        // start RxPacketTimer (packet timeout)...
        atomic { 
          macState = RX_P; 
          clearTFlag(&firedTimers, RX_PACKET_TIMER);
          restartRxPacketTimer(TRUE);
        }
      } else if (ms != INIT) {
        storeOldState(34);
        atomic { macState = RX; }
        call PhyPacketRx.recvHeader();
      }
    }

    async event void PhyPacketRx.recvFooterDone(bool error) {
      // stop RxPacketTimer (packet timeout)
      stopRxPacketTimer(TRUE);
    }

    /****** ChannelMonitor events *********************/

    async event error_t ChannelMonitor.channelBusy() {
      bool sendFailed = FALSE;
      atomic {
        if(macState == CCA) {
          ++inBackoff;
          clearTFlag(&firedTimers, BACKOFF_TIMER);
          storeOldState(58);
          if(inBackoff <= MAX_TX_ATTEMPTS) {
            storeOldState(60);
            restartBackoffTimer(TRUE);
          } else {
            storeOldState(61);
            sendFailed = TRUE;
            stopBackoffTimer(TRUE);
            inBackoff = 0;
          }
        } 
        stopMinClearTimer(TRUE);
        if(sendFailed) {
          post SendDoneFailTask();
        }
        macState = SW_RX;
        setRxMode();
      }
      return SUCCESS;
    }

    async event error_t ChannelMonitor.channelIdle() {
      atomic {
        if(macState == CCA) {
          if(!isTFlagSet(&firedTimers, MIN_CLEAR_TIMER)) {
            storeOldState(64);
            call ChannelMonitor.start();         
          } else {
            if(txBufPtr == NULL) {
              storeOldState(-64);
              signalFailure();
            }
            macState = SW_TX;
            setTxMode();
          }
        }
      }
      return SUCCESS;   
    }


    /****** ChannelMonitorControl events **************/
    event error_t ChannelMonitorControl.updateNoiseFloorDone() {
      error_t error;
      atomic {
        storeOldState(68);
        if(macState == INIT) {
          error = SUCCESS;
          macState = SW_RX;
          setRxMode();
          signal SplitControl.startDone(SUCCESS);
        } else {
          signalFailure();
          error = FAIL;
        }
      }
      return error;
    }

    /***** ChannelMonitorData events ******************/
    async event error_t ChannelMonitorData.getSnrDone(int16_t data) {
      atomic {
        if(macState == RX_P) {
          rssiValue = data;
        }
      }
      return SUCCESS;
    }

    /***** Radio Modes Stuff **************************/
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SleepModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}

    
}
