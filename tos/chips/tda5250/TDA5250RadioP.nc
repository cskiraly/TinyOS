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
* $Revision: 1.1.2.3 $
* $Date: 2006-01-23 00:54:44 $
* @author: Kevin Klues (klues@tkn.tu-berlin.de)
* ========================================================================
*/

module TDA5250RadioP {
  provides {
    interface Init;
    interface SplitControl;
    interface TDA5250Control;
    interface RadioByteComm;
  }
  uses {
    interface HPLTDA5250Config;
    interface HPLTDA5250Data;
    interface Resource as ConfigResource;
    // FIXME: Hier ResourceController (high priority client)
        interface Resource as DataResource;
  }
}

implementation {
  radioMode_t radioMode;  // Current Mode of the Radio
      float onTime, offTime;
      bool ccaMode;

      /**************** Radio Init *****************/
      command error_t Init.init() {
        radioMode = RADIO_MODE_OFF;
        return SUCCESS;
      }

      /**************** Radio Start  *****************/
      command error_t SplitControl.start() {
        radioMode_t mode;
        atomic mode = radioMode;
        if(mode == RADIO_MODE_OFF) {
          atomic radioMode = RADIO_MODE_ON_TRANSITION;
          return call ConfigResource.request();
        }
        return FAIL;
      }

      /**************** Radio Stop  *****************/
      command error_t SplitControl.stop(){
        atomic radioMode = RADIO_MODE_OFF_TRANSITION;
        return call ConfigResource.request();
      }

  /* radioBusy
      * This function checks whether the radio is busy
      * so as to decide whether it can perform some operation or not.
  */
      bool radioBusy() {
        switch(radioMode) {
          case RADIO_MODE_OFF:
          case RADIO_MODE_ON_TRANSITION:
          case RADIO_MODE_OFF_TRANSITION:
          case RADIO_MODE_TX_TRANSITION:
          case RADIO_MODE_RX_TRANSITION:
          case RADIO_MODE_CCA_TRANSITION:
          case RADIO_MODE_TIMER_TRANSITION:
          case RADIO_MODE_SELF_POLLING_TRANSITION:
          case RADIO_MODE_SLEEP_TRANSITION:
            return TRUE;
          default:
            return FALSE;
        }
      }

  /*
      event void ConfigResource.requested() {
}

      event void DataResource.requested() {
}
  */


      event void ConfigResource.granted() {
        radioMode_t mode;
        atomic mode = radioMode;
        switch(mode) {
          case RADIO_MODE_ON_TRANSITION:
            call HPLTDA5250Config.reset();
            call HPLTDA5250Config.SetRFPower(255);
            call HPLTDA5250Config.UsePeakDetector();
            call HPLTDA5250Config.SetClockOnDuringPowerDown();
            call HPLTDA5250Config.UseRSSIDataValidDetection(INIT_RSSI_THRESHOLD, TH1_VALUE, TH2_VALUE);
            call ConfigResource.release();
            atomic radioMode = RADIO_MODE_ON;
            signal SplitControl.startDone(SUCCESS);
            break;
          case RADIO_MODE_OFF_TRANSITION:
            call HPLTDA5250Config.SetClockOffDuringPowerDown();
            call HPLTDA5250Config.SetSleepMode();
            call ConfigResource.release();
            atomic radioMode = RADIO_MODE_OFF;
            signal SplitControl.stopDone(SUCCESS);
            break;
          case RADIO_MODE_TX_TRANSITION:
            call HPLTDA5250Config.SetSlaveMode();
            call HPLTDA5250Config.SetTxMode();
            break;
          case RADIO_MODE_RX_TRANSITION:
            call HPLTDA5250Config.SetSlaveMode();
            atomic ccaMode = FALSE;
            call HPLTDA5250Config.SetRxMode();
            break;
          case RADIO_MODE_CCA_TRANSITION:
            call HPLTDA5250Config.SetSlaveMode();
            atomic ccaMode = TRUE;
            call HPLTDA5250Config.SetRxMode();
            break;
          case RADIO_MODE_TIMER_TRANSITION:
            call HPLTDA5250Config.SetTimerMode(onTime, offTime);
            call ConfigResource.release();
            atomic radioMode = RADIO_MODE_TIMER;
            signal TDA5250Control.TimerModeDone();
            break;
          case RADIO_MODE_SELF_POLLING_TRANSITION:
            call HPLTDA5250Config.SetSelfPollingMode(onTime, offTime);
            call ConfigResource.release();
            atomic radioMode = RADIO_MODE_SELF_POLLING;
            signal TDA5250Control.SelfPollingModeDone();
            break;
          default:
            break;
        }
      }

      event void DataResource.granted() {
        radioMode_t mode;
        atomic mode = radioMode;
        switch(mode) {
          case RADIO_MODE_TX_TRANSITION:
            call HPLTDA5250Data.enableTx();
            atomic radioMode = RADIO_MODE_TX;
            signal TDA5250Control.TxModeDone();
            break;
          case RADIO_MODE_RX_TRANSITION:
            call HPLTDA5250Data.enableRx();
            atomic radioMode = RADIO_MODE_RX;
            signal TDA5250Control.RxModeDone();
            break;
          default:
            break;
        }
      }

  /**
      Set the mode of the radio
      The choices are TIMER_MODE, SELF_POLLING_MODE
  */
      async command error_t TDA5250Control.TimerMode(float on_time, float off_time) {
        atomic {
          if(radioBusy() == FALSE) {
            radioMode = RADIO_MODE_TIMER_TRANSITION;
            onTime = on_time;
            offTime = off_time;
          }
        }
        if(radioMode == RADIO_MODE_TIMER_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.ResetTimerMode() {
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_TIMER_TRANSITION;
        }
        if(radioMode == RADIO_MODE_TIMER_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.SelfPollingMode(float on_time, float off_time) {
        atomic {
          if(radioBusy() == FALSE) {
            radioMode = RADIO_MODE_SELF_POLLING_TRANSITION;
            onTime = on_time;
            offTime = off_time;
          }
        }
        if(radioMode == RADIO_MODE_SELF_POLLING_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.ResetSelfPollingMode() {
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_SELF_POLLING_TRANSITION;
        }
        if(radioMode == RADIO_MODE_SELF_POLLING_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.SleepMode() {
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_SLEEP_TRANSITION;
        }
        if(radioMode == RADIO_MODE_SLEEP_TRANSITION) {
          call HPLTDA5250Config.SetSleepMode();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.TxMode() {
        radioMode_t mode;
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_TX_TRANSITION;
        }
        atomic mode = radioMode;
        if(mode == RADIO_MODE_TX_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.RxMode() {
        radioMode_t mode;
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_RX_TRANSITION;
        }
        atomic mode = radioMode;
        if(mode == RADIO_MODE_RX_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async command error_t TDA5250Control.CCAMode() {
        atomic {
          if(radioBusy() == FALSE)
            radioMode = RADIO_MODE_CCA_TRANSITION;
        }
        if(radioMode == RADIO_MODE_CCA_TRANSITION) {
          call DataResource.release();
          call ConfigResource.request();
          return SUCCESS;
        }
        return FAIL;
      }

      async event void HPLTDA5250Data.txReady() {
        signal RadioByteComm.txByteReady(SUCCESS);
      }
      async event void HPLTDA5250Data.rxDone(uint8_t data) {
        signal RadioByteComm.rxByteReady(data);
      }

      async event void HPLTDA5250Config.SetTxModeDone() {
        call ConfigResource.release();
        call DataResource.request();
      }

      async event void HPLTDA5250Config.SetRxModeDone() {
        call ConfigResource.release();
        call DataResource.request();
      }
      async event void HPLTDA5250Config.SetSleepModeDone() {
        call HPLTDA5250Data.disableTx();
        call HPLTDA5250Data.disableRx();
        call DataResource.release();
        atomic radioMode = RADIO_MODE_SLEEP;
        signal TDA5250Control.SleepModeDone();
      }

      async event void HPLTDA5250Config.RSSIStable() {
        if(ccaMode == TRUE) {
          radioMode = RADIO_MODE_CCA;
          signal TDA5250Control.CCAModeDone();
        }
      }
      async event void HPLTDA5250Config.PWDDDInterrupt() {
        signal TDA5250Control.PWDDDInterrupt();
      }

      async command void RadioByteComm.txByte(uint8_t data) {
        error_t error = call HPLTDA5250Data.tx(data);
        if(error != SUCCESS)
          signal RadioByteComm.txByteReady(error);
      }

      async command bool RadioByteComm.isTxDone() {
        return call HPLTDA5250Data.isTxDone();
      }

      default async event void TDA5250Control.TimerModeDone(){
      }
      default async event void TDA5250Control.SelfPollingModeDone(){
      }
      default async event void TDA5250Control.RxModeDone(){
      }
      default async event void TDA5250Control.TxModeDone(){
      }
      default async event void TDA5250Control.SleepModeDone(){
      }
      default async event void TDA5250Control.CCAModeDone(){
      }
      default async event void TDA5250Control.PWDDDInterrupt() {
      }
      default async event void RadioByteComm.rxByteReady(uint8_t data) {
      }
      default async event void RadioByteComm.txByteReady(error_t error) {
      }
}
