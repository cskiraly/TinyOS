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
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250, switching modes and initializing.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 12:55:44 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module TDA5250M {
  provides {
    interface Init;
    interface SplitControl;
    interface TDA5250PacketControl;
    interface TDA5250Config;
    interface TDA5250Modes;
    interface Send;
    interface Receive;
  }
  uses {
    interface HPLTDA5250Config;
    interface HPLTDA5250Data;
    interface TDA5250Packet;
    interface Alarm<T32khz> as TransmitterDelay;
    interface Alarm<T32khz> as ReceiverDelay;
    interface Alarm<T32khz> as RSSIStableDelay;
    interface 
  }
}

implementation {
   uint16_t preamblesToSend;  // number of Preamble bytes to send
   radioMode_t radioMode;  // Current Mode of the Radio
   bool ccaMode;
   
   /* radioBusy
    * This function checks whether the radio is busy
    * so as to decide whether it can perform some operation or not.
    */      
   bool radioBusy() {
     radioMode_t currentRadioMode;
     atomic currentRadioMode = radioMode;   
     if(currentRadioMode == RADIO_MODE_PENDING)
       return TRUE;
     if(currentRadioMode == RADIO_MODE_SLEEP ||
        currentRadioMode == RADIO_MODE_TIMER ||
        currentRadioMode == RADIO_MODE_SELF_POLLING) {
       if(call BusArbitration.getBus() == FAIL)
         return TRUE;
       return FALSE;
     }     
     return FALSE;
   }    
   
   void RxModeDone() {
     bool busRequestedTemp;
     atomic busRequestedTemp = busRequested;
     if(busRequestedTemp) {
       Freeze();
       atomic busRequested = FALSE;
     }
     else {
       atomic {
         radioMode = RADIO_MODE_RX;
         rxState = RX_STATE_PREAMBLE;
       }        
       call HPLTDA5250Data.enableRx();
     }
   }   
   
   void DefaultSystemSetup() { 
     call Pot.set(255);
     call HPLTDA5250Data.disableRx();
     call HPLTDA5250Data.disableTx();
     call HPLTDA5250Config.reset();     
     call HPLTDA5250Config.UsePeakDetector();
     call HPLTDA5250Config.SetClockOnDuringPowerDown();
     call HPLTDA5250Config.UseRSSIDataValidDetection(INIT_RSSI_THRESHOLD, TH1_VALUE, TH2_VALUE);
     atomic radioMode = RADIO_MODE_NULL;   
     signal TDA5250Config.ready();
     signal TDA5250Modes.ready();     
   }   
   
   /*-------------------------------------------*/
   /*------------------ Tasks ------------------*/
   /*-------------------------------------------*/   
   /* UnFreeze
    * This task unfreezes the communication between 
    *  the Radio and the UART component.
    * It is posted everytime a freeze has occurred and
    *  whoever has taken over the UART has now released it.
    * Control of the UARt is given back to the Radio, and 
    *  communication continues
    */     
   task void UnFreeze() {
     if(call BusArbitration.getBus()) {
       call HPLTDA5250Data.disableTx();
       call HPLTDA5250Data.disableRx();
       atomic {
          radioMode = RADIO_MODE_RX;
          rxState = RX_STATE_PREAMBLE;
       }
       call HPLTDA5250Data.enableRx();     
     }
   }  
   
   task void StartupSignals() {   
     if(call BusArbitration.getBus() == SUCCESS)
       DefaultSystemSetup();
   }
   
   task void SignalRxModeDone() {   
     signal TDA5250Modes.RxModeDone();
   }   
   
   task void SignalCCAModeDone() {   
     signal TDA5250Modes.CCAModeDone();
   } 
   
   /*----------------------------------------------*/
   /*------------------ Commands ------------------*/
   /*----------------------------------------------*/
   command result_t StdControl.init(){
     atomic {
       radioMode = RADIO_MODE_PENDING;
       rxState = RX_STATE_NULL;
       txState = TX_STATE_NULL;
       busRequested = FALSE;
       ccaMode = FALSE;
       preamblesToSend = 0;
     }
     return SUCCESS;
   }

   /**************** Radio Start  *****************/
   command result_t StdControl.start() {
     return SUCCESS;
   }

   /**************** Radio Stop  *****************/
   command result_t StdControl.stop(){
      return SUCCESS;
   }

   /* all values to default */
   command result_t TDA5250Config.reset() {   
     if(radioBusy() == FALSE) {
       call HPLTDA5250Config.reset();
       return SUCCESS;
     }
     return FAIL;       
   }
      
   /**
      Set the mode of the radio 
      The choices are TIMER_MODE, SELF_POLLING_MODE
   */
   async command result_t TDA5250Modes.SetTimerMode(float on_time, float off_time) {  
     if(radioBusy() == FALSE) {
       call HPLTDA5250Data.disableTx();       
       call HPLTDA5250Data.disableRx();
       atomic radioMode = RADIO_MODE_TIMER;
       call HPLTDA5250Config.SetTimerMode(on_time, off_time);
       return SUCCESS;
     }
     return FAIL;       
   }
   
   async command result_t TDA5250Modes.ResetTimerMode() {   
     if(radioBusy() == FALSE) {     
       call HPLTDA5250Data.disableTx();       
       call HPLTDA5250Data.disableRx();
       atomic radioMode = RADIO_MODE_TIMER;
       call HPLTDA5250Config.ResetTimerMode();    
       return SUCCESS;
     }
     return FAIL;         
   }
   
   async command result_t TDA5250Modes.SetSelfPollingMode(float on_time, float off_time) {   
     if(radioBusy() == FALSE) {       
       call HPLTDA5250Data.disableTx();     
       call HPLTDA5250Data.disableRx();
       atomic radioMode = RADIO_MODE_SELF_POLLING;
       call HPLTDA5250Config.SetSelfPollingMode(on_time, off_time);  
       return SUCCESS;
     }
     return FAIL;     
   }
   
   async command result_t TDA5250Modes.ResetSelfPollingMode() {  
     if(radioBusy() == FALSE) {     
       call HPLTDA5250Data.disableTx();       
       call HPLTDA5250Data.disableRx();
       atomic radioMode = RADIO_MODE_SELF_POLLING;
       call HPLTDA5250Config.ResetSelfPollingMode();
       return SUCCESS;
     }
     return FAIL;     
   }
   
   /** 
      Sets the Potentiometer to a value between 0 and 255 
      for the output power from the transmitter 
   */
   command result_t TDA5250Config.SetRFPower(uint8_t value) { 
     if(radioBusy() == FALSE) {
       call Pot.set(value);
       return SUCCESS;
     }
     return FAIL;
   }
   
  command result_t TDA5250Config.UseLowTxPower() {
     if(radioBusy() == FALSE) {     
       call HPLTDA5250Config.UseLowTxPower();  
       return SUCCESS;
     }
     return FAIL;
  }   
  
  command result_t TDA5250Config.LowLNAGain() {
     if(radioBusy() == FALSE) {         
       call HPLTDA5250Config.LowLNAGain();  
       return SUCCESS;
     }
     return FAIL;
  } 
  
  async command result_t TDA5250Config.UseRCIntegrator() {
     if(radioBusy() == FALSE) {         
       call HPLTDA5250Config.UseRCIntegrator();  
       return SUCCESS;
     }
     return FAIL;  
  }
  async command result_t TDA5250Config.UsePeakDetector() {
     if(radioBusy() == FALSE) {         
       call HPLTDA5250Config.UsePeakDetector();  
       return SUCCESS;
     }
     return FAIL;  
  }
  
  async command result_t TDA5250Config.UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
     if(radioBusy() == FALSE) {         
       call HPLTDA5250Config.UseRSSIDataValidDetection(value, lower_bound, upper_bound);  
       return SUCCESS;
     }
     return FAIL;   
  }  
  
  async command result_t TDA5250Config.SetLowPassFilter(uint8_t data_cutoff) {
     if(radioBusy() == FALSE) {         
       call HPLTDA5250Config.SetLowPassFilter(data_cutoff);  
       return SUCCESS;
     }
     return FAIL;  
  }
  
  command result_t TDA5250Config.HighLNAGain() {
     if(radioBusy() == FALSE) {    
       call HPLTDA5250Config.HighLNAGain();  
       return SUCCESS;
     }
     return FAIL;
  }
   /**
      Switches radio between modes
   */
   async command result_t TDA5250Modes.RxMode() {
     if(radioBusy() == FALSE) { 
       if(radioMode == RADIO_MODE_CCA) {
         RxModeDone();
         post SignalRxModeDone();
         return SUCCESS;
       }
       
       if(radioMode == RADIO_MODE_SELF_POLLING) {
         call HPLTDA5250Config.SetSlaveMode();       
         RxModeDone();
         post SignalRxModeDone();
         return SUCCESS;
       }       
       if(radioMode == RADIO_MODE_TIMER)
         call HPLTDA5250Config.SetSlaveMode();
       call HPLTDA5250Data.disableRx();
       call HPLTDA5250Data.disableTx();                 
       atomic {
         radioMode = RADIO_MODE_PENDING;
         rxState = RX_STATE_NULL;
         txState = TX_STATE_NULL;
         ccaMode = FALSE;
       }
       call HPLTDA5250Config.SetRxState();      
       return SUCCESS;
     }
     return FAIL;
   }
   
   async command result_t TDA5250Modes.CCAMode() {
     if(radioBusy() == FALSE) { 
       if(radioMode == RADIO_MODE_RX) {
         call HPLTDA5250Data.disableRx();
         atomic radioMode = RADIO_MODE_CCA;
         post SignalCCAModeDone();
         return SUCCESS;
       }
/*            
       if(radioMode == RADIO_MODE_SELF_POLLING) {
         call HPLTDA5250Config.SetSlaveMode();       
         atomic radioMode = RADIO_MODE_CCA;
         post SignalCCAModeDone();
         return SUCCESS;
       }       
*/       
       if((radioMode == RADIO_MODE_TIMER) ||
          (radioMode == RADIO_MODE_SELF_POLLING))
         call HPLTDA5250Config.SetSlaveMode();       
       call HPLTDA5250Data.disableRx();
       call HPLTDA5250Data.disableTx();     
       atomic {
         radioMode = RADIO_MODE_PENDING;
         rxState = RX_STATE_NULL;
         txState = TX_STATE_NULL;
         ccaMode = TRUE;
       }    
       call HPLTDA5250Config.SetRxState();      
       return SUCCESS;
     }
     return FAIL;
   }      
      
   async command result_t TDA5250Modes.SleepMode() {
     if(radioBusy() == FALSE) {    
       if((radioMode == RADIO_MODE_TIMER) ||
          (radioMode == RADIO_MODE_SELF_POLLING))
         call HPLTDA5250Config.SetSlaveMode();     
       call HPLTDA5250Data.disableRx();
       call HPLTDA5250Data.disableTx();       
       atomic {
          radioMode = RADIO_MODE_PENDING;
          rxState = RX_STATE_NULL;
          txState = TX_STATE_NULL;
       }
       call HPLTDA5250Config.SetSleepState();
       return SUCCESS;
     }
     return FAIL;
   }
   
   async command result_t PacketTx.start(uint16_t numPreambles) {  
     if(radioBusy() == FALSE) {
       if((radioMode == RADIO_MODE_TIMER) ||
          (radioMode == RADIO_MODE_SELF_POLLING))       
         call HPLTDA5250Config.SetSlaveMode();     
       call HPLTDA5250Data.disableTx();
       call HPLTDA5250Data.disableRx();   
       atomic {
         radioMode = RADIO_MODE_PENDING;
         rxState = RX_STATE_NULL;
         txState = TX_STATE_PREAMBLE;
         preamblesToSend = numPreambles;
       }
       call HPLTDA5250Config.SetTxState();
       return SUCCESS;
     }
     return FAIL;
   }
   
   async command result_t PacketRx.reset() {
     bool currentBusRequested, currentRadioMode;
     atomic {
       currentBusRequested = busRequested;
       currentRadioMode = radioMode;
     }
     if(currentRadioMode == RADIO_MODE_RX) {
       if(currentBusRequested) {
         Freeze();
         atomic busRequested = FALSE;
       }
       else atomic rxState = RX_STATE_PREAMBLE;
     }
     return SUCCESS;
   }
   
   async command result_t ByteComm.txByte(uint8_t data) {
     call HPLTDA5250Data.tx(data);
     return SUCCESS;
   }
   
   async command result_t PacketTx.stop() {
     while(call HPLTDA5250Data.isTxDone() == FAIL);      
     atomic txState = TX_STATE_NULL;
     call HPLTDA5250Data.disableTx();
     signal PacketTx.done();
     return SUCCESS;
   }
   
   /**************** USART Tx Done ****************/
   async event void HPLTDA5250Data.txReady() {      
     TransmitNextByte();
   }

   /**************** USART Rx Done ****************/
   async event void HPLTDA5250Data.rxDone(uint8_t data) { 
     ReceiveNextByte(data);
   }
  
   /**
      Sets the threshold Values for internal evaluation
   */
   command result_t TDA5250Config.SetRSSIThreshold(uint8_t value) {
     if(radioBusy() == FALSE) { 
       call HPLTDA5250Config.SetRSSIThreshold(value);  
       return SUCCESS;
     }
     return FAIL;   
   }
   command result_t TDA5250Config.DataValidDetectionOn() {  
     if(radioBusy() == FALSE) {  
       call HPLTDA5250Config.UseDataValidDetection();
       return SUCCESS;
     }
     return FAIL;        
   }
   command result_t TDA5250Config.DataValidDetectionOff() { 
     if(radioBusy() == FALSE) {    
       call HPLTDA5250Config.UseDataAlwaysValid();
       return SUCCESS;
     }
     return FAIL;
   }
   
   command result_t TDA5250Config.SetClockOffDuringPowerDown() {  
     if(radioBusy() == FALSE) {    
       call HPLTDA5250Config.SetClockOffDuringPowerDown();
       return SUCCESS;
     }
     return FAIL;
   }
   
   command result_t TDA5250Config.SetClockOnDuringPowerDown() {  
     if(radioBusy() == FALSE) {    
       call HPLTDA5250Config.SetClockOnDuringPowerDown();
       return SUCCESS;
     }
     return FAIL;
   }   
   
   /**
      Interrupt avialable on the PWD_DD pin when in 
      TIMER_MODE or SELF_POLLING_MODE
   */   
   async event void HPLTDA5250Config.PWD_DDInterrupt() {
     signal TDA5250Modes.interrupt();
   }
   
   
   event void HPLTDA5250Config.ready() {
     if(call BusArbitration.getBus() == SUCCESS)
       DefaultSystemSetup();
     else atomic radioMode = RADIO_MODE_STARTUP;
   }
   
   event void HPLTDA5250Config.SetRxStateDone() {
     if(ccaMode == FALSE) {
       RxModeDone();
       signal TDA5250Modes.RxModeDone();
     }
   }
   
   event void HPLTDA5250Config.RSSIStable() {
     if(ccaMode == TRUE) {
       atomic radioMode = RADIO_MODE_CCA;
       signal TDA5250Modes.CCAModeDone();
     }
   }
   
   event void HPLTDA5250Config.SetSleepStateDone() {
     atomic radioMode = RADIO_MODE_SLEEP;   
     call BusArbitration.releaseBus(); 
     signal TDA5250Modes.SleepModeDone();   
   }   

   event void HPLTDA5250Config.SetTxStateDone() {
     atomic radioMode = RADIO_MODE_TX;    
     call HPLTDA5250Data.enableTx();
     TransmitNextByte();
   }
   
  event result_t BusArbitration.busRequested() {
    rxState_t currentRxState;
    TOSH_uwait(521); // Length of one byte period
    atomic currentRxState = rxState;
    if(currentRxState == RX_STATE_PREAMBLE)
      Freeze();
    else atomic busRequested = TRUE;
    return SUCCESS;
  }
   
  event result_t BusArbitration.busReleased() {
    radioMode_t currentRadioMode;
    atomic currentRadioMode = radioMode;
    if(currentRadioMode == RADIO_MODE_FROZEN)
      post UnFreeze();    
    else if(currentRadioMode == RADIO_MODE_STARTUP)
      post StartupSignals();          
    return SUCCESS;
  }
  
  async command result_t PacketRx.waitingForSFD() {
    rxState_t rxStateTemp;
    atomic rxStateTemp = rxState;
    if(rxStateTemp == RX_STATE_SYNC)
      return SUCCESS;
    else return FAIL;
  } 
  
  void TransmitNextByte() {
    txState_t currentTxState;
    atomic currentTxState = txState;
    switch(currentTxState) {   
      case TX_STATE_PREAMBLE:
        atomic {
          if(preamblesToSend > 0)
            preamblesToSend--;
          else txState = TX_STATE_SYNC;            
        }
        call HPLTDA5250Data.tx(PREAMBLE_BYTE);
        break;
      case TX_STATE_SYNC:
        atomic txState = TX_STATE_SFD;
        call HPLTDA5250Data.tx(SYNC_BYTE);
        break;
      case TX_STATE_SFD:
        atomic txState = TX_STATE_DATA;
        call HPLTDA5250Data.tx(SFD_BYTE);
        break;
      case TX_STATE_DATA:
        signal ByteComm.txByteReady(SUCCESS);  
        break;
      default:
        break;                     
    }  
  }
 
  void ReceiveNextByte(uint8_t data) {
    rxState_t currentRxState;
    atomic currentRxState = rxState;
    switch(currentRxState) {
      case RX_STATE_PREAMBLE:
       if(data == PREAMBLE_BYTE)
         atomic rxState = RX_STATE_SYNC;
      case RX_STATE_SYNC:
        if(data != PREAMBLE_BYTE) {
           if (data == SFD_BYTE) {
             atomic rxState = RX_STATE_DATA;
             signal PacketRx.detected();
           }
           else atomic rxState = RX_STATE_SFD;
        }
        break;
      case RX_STATE_SFD:         
        if (data == SFD_BYTE) {
           atomic rxState = RX_STATE_DATA;
           signal PacketRx.detected();
        }
        else
           atomic rxState = RX_STATE_PREAMBLE;
        break;
      case RX_STATE_DATA:
        signal ByteComm.rxByteReady(data, 0, 0);
        break;
      default:
        break;
    }
  }
  
  default async event result_t ByteComm.txDone() {
    return SUCCESS;
  }
  default async event result_t ByteComm.txByteReady(bool success) {
    return success;
  }
  default async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
    return SUCCESS;
  }
  default async event result_t PacketRx.detected() {
    return SUCCESS;
  }
  default async event void TDA5250Modes.interrupt() {
  }   
  default event result_t TDA5250Modes.RxModeDone(){
     return SUCCESS;
  }
  default event result_t TDA5250Modes.SleepModeDone(){
     return SUCCESS;
  }
  default event result_t TDA5250Modes.CCAModeDone(){
     return SUCCESS;
  }  
  default event result_t TDA5250Config.ready() {
     return SUCCESS;
  }
  default event result_t TDA5250Modes.ready(){
    return SUCCESS;
  } 
}
