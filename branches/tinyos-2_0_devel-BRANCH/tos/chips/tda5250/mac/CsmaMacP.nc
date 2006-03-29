/*
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


#include "radiopacketfunctions.h"
#include "flagfunctions.h"

module CsmaMacP {
    provides {
      interface Init;
      interface SplitControl;
      interface Send;
      interface Receive;
    }
    uses {
      interface StdControl as CcaStdControl;
      interface AsyncSend as PacketSend;
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
#define MACM_DEBUG                              // debug...
#define RX_PACKET_TIME (TOSH_DATA_LENGTH+2)<<2  //max. Packet duration in ms 
#define MINISLOT_TIME 31                        //minislot time  in ms
#define DIFS 1                                  // for atomic acks: allow  between packet and ACK (in ms)
#define RX_THRESHOLD 13                         // SNR should be at least RX_THRESHOLD dB before RX attempt
#define MAX_TX_ATTEMPTS 5                       // drop packet if we see the channel busy MAX_TX_ATTEMPTS times in a row 


    
    /**************** Module Global Variables  *****************/
    
    /* Packet vars */
    message_t* txBufPtr;
    uint8_t txLen;
    int16_t rssiValue;

    /* state vars & defs */
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
    
    /** the value in this variable denotes how often we have seen
    * the channel busy when trying to access it
    */
    uint8_t inBackoff;
    
    /* timer vars & defs */
    typedef enum {
      MIN_CLEAR_TIMER = 1,
      RX_PACKET_TIMER = 2,
      BACKOFF_TIMER = 4,
    } timerPos_t;

    uint8_t dirtyTimers;
    uint8_t firedTimers;
    uint8_t runningTimers;
    uint8_t restartTimers;

    /** on and off times for preamble sampling mode in jiffies */
    uint16_t slotModulo;

    
    /****** debug vars & defs & functions  ***********************/
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

    void signalFailure() {
#ifdef MACM_DEBUG
      atomic {
        for(;;) {
          ;
        }
      }
#endif
    }

    
    /****** Helper tasks *****************************/
    
    task void SendDoneFailTask();
    task void SendDoneSuccessTask();
    task void RetrySendTask();
    
    task void StopMinClearTimerTask();
    task void StopRxPacketTimerTask();
    task void StopBackoffTimerTask();


    /****** Timer handling  **********************/

    // cs = clear and maybe start, only start if start requested and in correct
    // mac state
    task void CSMinClearTimerTask()   {
      atomic {
        clearFlag(&dirtyTimers, MIN_CLEAR_TIMER);
        if(isFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
          if(macState == CCA) {
            call MinClearTimer.startOneShot(DIFS);
            clearFlag(&restartTimers, MIN_CLEAR_TIMER);
            setFlag(&runningTimers, MIN_CLEAR_TIMER);
          } else {
            clearFlag(&restartTimers, MIN_CLEAR_TIMER);
          }
        }
      }
    };
    
    task void CSRxPacketTimerTask()    {
      atomic {
        clearFlag(&dirtyTimers, RX_PACKET_TIMER);
        if(isFlagSet(&restartTimers, RX_PACKET_TIMER)) {
          if(macState == RX_P) {
            call RxPacketTimer.startOneShot(RX_PACKET_TIME) ;
            clearFlag(&restartTimers, RX_PACKET_TIMER);
            setFlag(&runningTimers, RX_PACKET_TIMER);
          } else {
            clearFlag(&restartTimers, RX_PACKET_TIMER);
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
        clearFlag(&dirtyTimers, BACKOFF_TIMER);
        if(isFlagSet(&restartTimers, BACKOFF_TIMER)) {
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
          clearFlag(&restartTimers, BACKOFF_TIMER);
          setFlag(&runningTimers, BACKOFF_TIMER);
        }
      }
    }

    void csMinClearTimer(bool inAsync) {
      atomic {
        if(isFlagSet(&runningTimers, MIN_CLEAR_TIMER)) {
          setFlag(&dirtyTimers, MIN_CLEAR_TIMER);
          if(inAsync) {
            post StopMinClearTimerTask();
          } else {
            clearFlag(&runningTimers, MIN_CLEAR_TIMER);
            call MinClearTimer.stop();
            post CSMinClearTimerTask();
          }
        } else if(isFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
          post CSMinClearTimerTask();
        }
      }
    }
    task void StopMinClearTimerTask() { csMinClearTimer(FALSE); }
    void stopMinClearTimer(bool inAsync) {
      clearFlag(&restartTimers, MIN_CLEAR_TIMER);
      csMinClearTimer(inAsync);
    }
    void restartMinClearTimer(bool inAsync) {
      setFlag(&restartTimers, MIN_CLEAR_TIMER);
      csMinClearTimer(inAsync);
    }

    void csRxPacketTimer(bool inAsync) {
      atomic {
        if(isFlagSet(&runningTimers, RX_PACKET_TIMER)) {
          setFlag(&dirtyTimers, RX_PACKET_TIMER);
          if(inAsync) {
            post StopRxPacketTimerTask();
          } else {
            clearFlag(&runningTimers, RX_PACKET_TIMER);
            call RxPacketTimer.stop();
            post CSRxPacketTimerTask();
          }
        }
        else if(isFlagSet(&dirtyTimers, RX_PACKET_TIMER)) {
            // do nothing
        }
        else if(isFlagSet(&restartTimers, RX_PACKET_TIMER)) {
          post CSRxPacketTimerTask();
        }
      }
    }
    task void StopRxPacketTimerTask() { csRxPacketTimer(FALSE); };
    void stopRxPacketTimer(bool inAsync) {
        clearFlag(&restartTimers, RX_PACKET_TIMER);
        csRxPacketTimer(inAsync);
    };
    void restartRxPacketTimer(bool inAsync) {
      setFlag(&restartTimers, RX_PACKET_TIMER);
      csRxPacketTimer(inAsync);
    };

    void csBackoffTimer(bool inAsync) {
      atomic {
        if(isFlagSet(&runningTimers, BACKOFF_TIMER)) {
          setFlag(&dirtyTimers, BACKOFF_TIMER);
          if(inAsync) {
            post StopBackoffTimerTask();
          } else {
            clearFlag(&runningTimers, BACKOFF_TIMER);
            call BackoffTimer.stop();
            post CSBackoffTimerTask();
          }
        }
        else if(isFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
            // do nothing
        }
        else if(isFlagSet(&restartTimers, BACKOFF_TIMER)) {
          post CSBackoffTimerTask();
        }
      }
    }
    task void StopBackoffTimerTask() { csBackoffTimer(FALSE); };
    void stopBackoffTimer(bool inAsync) {
      clearFlag(&restartTimers, BACKOFF_TIMER);
      csBackoffTimer(inAsync);
    };
    void restartBackoffTimer(bool inAsync) {
      setFlag(&restartTimers, BACKOFF_TIMER);
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
      if (ms == SW_RX) setRxMode();
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
    task void StartDone() {
      macState_t ms;
      atomic ms = macState;
      if (ms == RX) {
        signal SplitControl.startDone(SUCCESS);
      } else if (ms == INIT) {
        atomic macState = SW_RX;
        setRxMode();
        post StartDone();
      } else {
        post StartDone();
      }
    }
    
    command error_t SplitControl.start() {
      call CcaStdControl.start();
      atomic {
        if (macState == INIT) {
          setCCAMode();
        } else {
          setRxMode();
          post StartDone();
        }
      }
      return SUCCESS;
    }

    task void StopDone() {
      atomic {
        if (macState != RX) {
          post StopDone();
        } else {
          txBufPtr = NULL;
          macState = SW_RX;
          inBackoff = 0;
          firedTimers = 0;
          dirtyTimers = 0;
          runningTimers = 0;
          call MinClearTimer.stop();
          call RxPacketTimer.stop();
          call BackoffTimer.stop();
          signal SplitControl.stopDone(SUCCESS); 
        }
      }
    }
    
    command error_t SplitControl.stop() {
      call CcaStdControl.stop();
      post StopDone();
      return SUCCESS;
    }
  
    
    /****** RadioMode events *************************/
    
    async event void RadioModes.CCAModeDone() {
      atomic  {
        if(macState == SW_CCA)  {
          if(call ChannelMonitor.start() == SUCCESS) {
            clearFlag(&firedTimers, MIN_CLEAR_TIMER);
            restartMinClearTimer(FALSE);
            storeOldState(1);
            macState = CCA;
          } else {
            storeOldState(2);
            setCCAMode();
          }
        } else if(macState == INIT) {
          storeOldState(3);
          if ( (call ChannelMonitorControl.updateNoiseFloor() == FAIL)  ) {
            setCCAMode(); 
          } 
        } else {
          storeOldState(4);
        }
      }
    }

    async event void RadioModes.RxModeDone() {
      atomic {
        if( macState == SW_RX ) {
          storeOldState(5);
          macState = RX;
          call PhyPacketRx.recvHeader();
        } else {
          storeOldState(-5);
          signalFailure();
        }
      }
    }

    async event void RadioModes.TxModeDone() {
      error_t error = FAIL;
      atomic {
        if(macState == SW_TX) {
          storeOldState(6);
          macState = TX_P;
          clearFlag(&firedTimers, MIN_CLEAR_TIMER);
          clearFlag(&firedTimers, BACKOFF_TIMER);
          error = call PacketSend.send(txBufPtr, txLen);
          if( error != SUCCESS) {
            storeOldState(-7);
            post RetrySendTask();
          } else {
            storeOldState(7);
          }
        }
        else {
          storeOldState(-6);
          signalFailure(); 
        }
      }
    }
    
    
    /****** Send / Receive *********************/
    
    task void SendDoneFailTask() {
      message_t *msg;
      atomic {
        msg = txBufPtr;
        txBufPtr = NULL;
      }
      signal Send.sendDone(msg, FAIL);
    }
    
    task void SendDoneSuccessTask() {
      message_t *msg;
      atomic {
        msg = txBufPtr;
        txBufPtr = NULL;
      }
      signal Send.sendDone(msg, SUCCESS);
    }
    
    task void RetrySendTask() {
      atomic {
        ++inBackoff;
        if(inBackoff <= MAX_TX_ATTEMPTS) {
          storeOldState(8);
          macState = SW_CCA;
          setCCAMode();
          restartBackoffTimer(TRUE);
        } else {
          storeOldState(9);
          inBackoff = 0;
          stopBackoffTimer(FALSE);
          post SendDoneFailTask();
        }
      }
    }
    
    command error_t Send.send(message_t* msg, uint8_t len) {
      atomic {
        if(inBackoff == 0) {
          storeOldState(10);
          switch(macState) {
            case SW_RX:
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
          storeOldState(11);
        }
      }
      return EBUSY;
    }

    command void* Send.getPayload(message_t* msg) {
      return call Packet.getPayload(msg, (uint8_t*)&(getHeader(msg)->length));
    }

    command uint8_t Send.maxPayloadLength() {
      return call Packet.maxPayloadLength();
    }

    command error_t Send.cancel(message_t* msg) {
      atomic {
        if (macState != TX_P) {
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

    
    /****** PacketSerializer events **********************/

    event message_t* PacketReceive.receive(message_t* msg, void* payload, uint8_t len) {
      atomic {
        storeOldState(12);
        if( isFlagSet(&firedTimers, BACKOFF_TIMER) && (inBackoff > 0)) {
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

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
      if (error == SUCCESS) {
        atomic {
          if(macState == TX_P) { 
            storeOldState(13);
            stopBackoffTimer(TRUE);
            inBackoff = 0;
            macState = SW_RX;
            setRxMode();
          } else {
            storeOldState(-13);
            signalFailure();
          }
          post SendDoneSuccessTask();
        }
      } else {
        post RetrySendTask(); 
      }
    }
    
    
    /******* PhyPacketRx *******************************/
    
    async event void PhyPacketRx.recvHeaderDone() {
      macState_t ms = RX;
      atomic { ms = macState; }
      if(ms == RX) {
        storeOldState(14);
        call ChannelMonitor.rxSuccess();
        atomic { 
          macState = RX_P; 
          call ChannelMonitorData.getSnr();
          clearFlag(&firedTimers, RX_PACKET_TIMER);
          restartRxPacketTimer(TRUE);
        }
      } else {
        storeOldState(-14);
        // we lose this packet 'cause we already switched the radio mode
      }
    }

    async event void PhyPacketRx.recvFooterDone(bool error) {
      // stop RxPacketTimer (packet timeout)
      stopRxPacketTimer(TRUE);
    }

       
    
    /****** MinClearTimer ******************************/
    
    event void MinClearTimer.fired() {
      atomic {
        if(isFlagSet(&dirtyTimers, MIN_CLEAR_TIMER)) {
          storeOldState(15);
        } else {
          if(macState == CCA) {
            setFlag(&firedTimers, MIN_CLEAR_TIMER);
            storeOldState(16);
          } else {
            storeOldState(-16);
            signalFailure();
          }
          clearFlag(&runningTimers, MIN_CLEAR_TIMER);
        }
      }
    }

    
    /****** RxPacketTimer ******************************/
    
    event void RxPacketTimer.fired() {
      atomic {
        if(isFlagSet(&dirtyTimers, RX_PACKET_TIMER)) {
          storeOldState(17);
        }
        else {
          if(macState == RX_P) {
            storeOldState(18);
            setFlag(&firedTimers, RX_PACKET_TIMER);
            stopRxPacketTimer(FALSE);
            if( isFlagSet(&firedTimers, BACKOFF_TIMER) && (inBackoff > 0) ) {
              macState = SW_CCA;
              setCCAMode();
            } else {
              macState = RX;
              // reset PhyPacket state...    
              call PhyPacketRx.recvHeader();
            }
          } else {
            storeOldState(-18);
            signalFailure();
          }
          clearFlag(&runningTimers, RX_PACKET_TIMER);
        }
      }
    }

    
    /****** BackoffTimer ******************************/

    event void BackoffTimer.fired() {
      macState_t ms = RX;
      atomic {
        if(isFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
          storeOldState(19);
        }
        else {
          if ((macState == RX) || (macState == SW_RX)) {
            storeOldState(20);
            ms = SW_CCA;
          } else if (macState == INIT) {
            storeOldState(21);
            ms = INIT;
          } else {
            setFlag(&firedTimers, BACKOFF_TIMER);
            storeOldState(22);
          }
          clearFlag(&runningTimers, BACKOFF_TIMER);
        }
      }
      if(ms == INIT) {
        restartBackoffTimer(FALSE);
      } else if (ms == SW_CCA) {
        atomic macState = SW_CCA;
        setCCAMode();
      }
    }

    
    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
      bool sendFailed = FALSE;
      atomic {
        if(macState == CCA) {
          ++inBackoff;
          clearFlag(&firedTimers, BACKOFF_TIMER);
          storeOldState(23);
          if(inBackoff <= MAX_TX_ATTEMPTS) {
            storeOldState(24);
            restartBackoffTimer(TRUE);
          } else {
            storeOldState(25);
            sendFailed = TRUE;
            inBackoff = 0;
            stopBackoffTimer(TRUE);
          }
        } 
        stopMinClearTimer(TRUE);
        if(sendFailed) {
          post SendDoneFailTask();
        }
        macState = SW_RX;
        setRxMode();
      }
    }

    async event void ChannelMonitor.channelIdle() {
      atomic {
        if(macState == CCA) {
          if(!isFlagSet(&firedTimers, MIN_CLEAR_TIMER)) {
            storeOldState(26);
            call ChannelMonitor.start();         
          } else {
            if(txBufPtr == NULL) {
              storeOldState(-26);
              signalFailure();
            }
            macState = SW_TX;
            setTxMode();
          }
        }
      }  
    }


    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
      atomic {
        storeOldState(27);
        if(macState == INIT) {
          post StartDone();
        } else {
          signalFailure();
        }
      }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
      atomic {
        if(macState == RX_P) {
          rssiValue = data;
        }
      }
    }

    
    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SleepModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}

    
}
