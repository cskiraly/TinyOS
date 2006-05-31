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
      interface MacSend;
      interface MacReceive;
    }
    uses {
      interface StdControl as CcaStdControl;
      interface PhySend as PacketSend;
      interface PhyReceive as PacketReceive;
        
      interface Tda5250Control as RadioModes;  

      interface UartPhyControl;
      
      interface ChannelMonitor;
      interface ChannelMonitorControl;  
      interface ChannelMonitorData;

      interface Random;
        
      interface Alarm<T32khz, uint16_t> as MinClearTimer;
      interface Timer<TMilli> as BackoffTimer;
    }
}
implementation
{
#define MACM_DEBUG                              // debug...
#define MINISLOT_TIME 55                        // minislot time  in ms
#define DIFS 2                                  // for atomic acks: allow  between packet and ACK (in ms)
#define RX_THRESHOLD 13                         // SNR should be at least RX_THRESHOLD dB before RX attempt
#define MAX_TX_ATTEMPTS 5                       // drop packet if we see the channel busy MAX_TX_ATTEMPTS times in a row 


    
    /**************** Module Global Variables  *****************/
    
    /* Packet vars */
    message_t* txBufPtr;
    uint8_t txLen;
    int16_t rssiValue;


    /* state vars & defs */
    typedef enum {
      SW_CCA,          // switch to CCA
      CCA,             // clear channel assessment     
      SW_RX,           // switch to receive
      RX,              // rx mode done, listening & waiting for packet
      INIT,
      SW_TX,           // switch to Tx mode
      TX_P,            // transmitting packet
      RX_P,            // receive packet
      SWITCH           // force switching radio states
    } macState_t;

    macState_t macState;
    
    /** the value in this variable denotes how often we have seen
    * the channel busy when trying to access it
    */
    uint8_t inBackoff;
    
    /* timer vars & defs */
    typedef enum {
      MIN_CLEAR_TIMER = 1,
      BACKOFF_TIMER = 2,
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
    task void RetrySendTask();
    task void StopBackoffTimerTask();


    /****** Timer handling  **********************/

    // cs = clear and maybe start, only start if start requested and in correct
    // mac state
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
    void setCCAMode();
    void setRxMode();
    void setTxMode();
    
    /****** startCCA with Min. Clear Timer ****************************/
    void startCCA() {
      if(call ChannelMonitor.start() == SUCCESS) {
        clearFlag(&firedTimers, MIN_CLEAR_TIMER);
        call MinClearTimer.start(DIFS);
        storeOldState(1);
      } else {
        storeOldState(2);
        atomic macState = SWITCH;
        setCCAMode();
      }
    }
    
    void setCCAMode() {
      atomic {
        switch (macState) {
          case SW_CCA:
          case SW_RX:
            macState = SW_CCA;
            break;
          case CCA:
          case RX:
          case RX_P:
            macState = CCA;
            startCCA();
            break;
          case INIT:
            if(call RadioModes.RxMode() == SUCCESS) {
              storeOldState(0);
            } else {
              post CCAModeTask();
            }
            break;
          default: 
            macState = SW_CCA;
            if(call RadioModes.RxMode() == SUCCESS) {
              storeOldState(0);
            } else {
              post CCAModeTask();
            }
            break;
        }
      }
    }

    task void CCAModeTask() {
      macState_t ms;
      atomic ms = macState;
      if((ms == SW_CCA) || (ms == INIT)) setCCAMode();
    }

    void setRxMode() {
      atomic {
        switch (macState) {
          case SW_CCA:
          case SW_RX:
            macState = SW_RX;
            break;
          case RX_P:
          case RX:
          case CCA:
            macState = RX;
            break;
          default:   
            macState = SW_RX;
            if(call RadioModes.RxMode() == FAIL) {
              post SetRxModeTask();
            } 
            break;
        }
      }
    }

    task void SetRxModeTask() {
      macState_t ms;
      atomic ms = macState;
      if (ms == SW_RX ) setRxMode();
    }
    
    void setTxMode() {
      atomic macState = SW_TX;
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
        slotModulo = MINISLOT_TIME; 
#ifdef MACM_DEBUG
        histIndex = 0;
#endif
      }
      return SUCCESS;
    }

    /****************  SplitControl  *****************/
    task void StartDone() {
      atomic {
        if (macState == RX) {
          signal SplitControl.startDone(SUCCESS);
        } else if (macState == INIT) {
          setRxMode();
          post StartDone();
        } else {
          post StartDone();
        }
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
          macState = SWITCH;
          inBackoff = 0;
          firedTimers = 0;
          dirtyTimers = 0;
          runningTimers = 0;
          call MinClearTimer.stop();
          stopBackoffTimer(FALSE);
          signal SplitControl.stopDone(SUCCESS); 
        }
      }
    }
    
    command error_t SplitControl.stop() {
      call CcaStdControl.stop();
      post StopDone();
      return SUCCESS;
    }
    
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
      atomic  {
        if(macState == SW_CCA)  {
          macState = CCA;
          startCCA();
        } else if(macState == INIT) {
          storeOldState(3);
          if ( (call ChannelMonitorControl.updateNoiseFloor() == FAIL)  ) {
            setCCAMode(); 
          } 
        } else if (macState == SW_RX) {
          macState = RX;
          storeOldState(4);
        }
      }
    }

    async event void RadioModes.RxModeDone() {
      storeOldState(5);
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
    task void RetrySendTask() {
      message_t *msg;
      atomic {
        ++inBackoff;
        if(inBackoff <= MAX_TX_ATTEMPTS) {
          storeOldState(8);
          setCCAMode();
          restartBackoffTimer(FALSE);
        } else {
          storeOldState(9);
          inBackoff = 0;
          stopBackoffTimer(FALSE);
          msg = txBufPtr;
          txBufPtr = NULL;
          signal MacSend.sendDone(msg, FAIL);
        }
      }
    }
    
    async command error_t MacSend.send(message_t* msg, uint8_t len) {
      atomic {
        if(inBackoff == 0) {
          storeOldState(10);
          switch(macState) {
            case RX:
            case SW_RX:
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

    async command error_t MacSend.cancel(message_t* msg) {
       atomic {
         if ( (macState != TX_P) || (macState != SW_TX) || (macState != CCA) ) {
           stopBackoffTimer(TRUE);
           call MinClearTimer.stop();
           txBufPtr = 0;
           inBackoff = 0;
           signal MacSend.sendDone(msg, ECANCEL);
           return SUCCESS;
         } else {
           return FAIL;
         }
       } 
     }

     task void TestTask() {
       unsigned i;
       for(i = 0; i < 10000; i++){
         ;
       }
     }
     
    /****** PacketSerializer events **********************/
    async event void PacketReceive.receiveDetected() {
      atomic {
//        if ( (macState == SW_CCA) || (macState == CCA) || (macState == RX) || (macState == SW_RX) ) {
          if(macState <= RX) {
          macState = RX_P;
          storeOldState(14);
          call ChannelMonitor.rxSuccess();
          //FIXME: problems when calling this -> packets get lost
          call  ChannelMonitorData.getSnr();
          post TestTask();
        } else {
          storeOldState(-14);
          // we lose this packet 'cause we already switched the radio mode to SW_TX or TX
        } 
      }
    }

    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
      atomic {
        storeOldState(12);
        if (macState != INIT) {
          if( (isFlagSet(&firedTimers, BACKOFF_TIMER)) && (inBackoff > 0)) {
            setCCAMode();
          } else {
            setRxMode();
          }
        }
      }
      if (error == SUCCESS) {
        atomic {
          (getMetadata(msg))->strength = rssiValue;
        }
        signal MacReceive.receiveDone(msg);
      }
      return msg;
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
      if (error == SUCCESS) {
        atomic {
          if(macState == TX_P) { 
            storeOldState(13);
            stopBackoffTimer(TRUE);
            inBackoff = 0;
            setRxMode();
          } else {
            storeOldState(-13);
            signalFailure();
          }
          txBufPtr = NULL;
          signal MacSend.sendDone(msg, SUCCESS);
        }
      } else {
        post RetrySendTask(); 
      }
    }
       
    
    /****** MinClearTimer ******************************/
    
    async event void MinClearTimer.fired() {
      atomic {
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

    
    /****** BackoffTimer ******************************/

    event void BackoffTimer.fired() {
      atomic {
        if(isFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
          storeOldState(19);
        }
        else {
          if ((macState == RX) || (macState == SW_RX)) {
            storeOldState(20);
            if (call UartPhyControl.isBusy() == FALSE) {
              setCCAMode();
            } else {
              setRxMode();
            } 
          } else if (macState == INIT) {
            storeOldState(21);
            restartBackoffTimer(FALSE);
          } 
          setFlag(&firedTimers, BACKOFF_TIMER);
          storeOldState(22);
          clearFlag(&runningTimers, BACKOFF_TIMER);
        }
      }
    }

    
    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
      message_t *msg;
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
            msg = txBufPtr;
            txBufPtr = NULL;
            signal MacSend.sendDone(msg, FAIL);
          }
        } 
        call MinClearTimer.stop();
        setRxMode();
      }
    }

    async event void ChannelMonitor.channelIdle() {
      atomic {
        if(macState == CCA) {
          if(!isFlagSet(&firedTimers, MIN_CLEAR_TIMER)) {
            storeOldState(26);
	    // until min. clear timer is fired...
            call ChannelMonitor.start();         
          } else {
            if(txBufPtr == NULL) {
              storeOldState(-26);
              signalFailure();
            }
            setTxMode();
          }
        }
      }  
    }


    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
      atomic {
        if(macState == INIT) {
          storeOldState(27);
          post StartDone();
        } else {
          storeOldState(-27);
          signalFailure();
        }
      }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
      atomic {
        if (macState == RX_P) rssiValue = data;
      }
    }

    
    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SleepModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}

    
}

