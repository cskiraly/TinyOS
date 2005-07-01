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
 * $Date: 2005-07-01 13:05:12 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module TDA5250RadioM {
  provides {
    interface Init;
    interface SplitControl;
    interface RadioByteComm;
    interface TDA5250Control;
    interface TDA5250Config;
  }
  uses {
    interface HPLTDA5250Config;
    interface HPLTDA5250Data;
		interface Resource as DataResource;
		interface Resource as ConfigResource;
  }
}

implementation {
   radioMode_t radioMode;  // Current Mode of the Radio
   bool ccaMode;
	 
   /**************** Radio Init *****************/	 
   command result_t Init.init(){
     atomic {
       radioMode = RADIO_MODE_OFF;
       rxState = RX_STATE_NULL;
       txState = TX_STATE_NULL;
     }
     return SUCCESS;
   }	 
	 
   /**************** Radio Start  *****************/
   command error_t SplitControl.start() {
	   if(radioMode == RADIO_MODE_OFF) {
		   atomic radioMode = RADIO_MODE_STARTING;
		   call ConfigResource.request();
       return SUCCESS;
		 }
		 return FAIL;
   }
	 
   /**************** Radio Stop  *****************/
   command error_t SplitControl.stop(){
	    if(radioMode != RADIO_MODE_BUSY)
			  atomic radioMode = RADIO_MODE_STOPPING;
			  call ConfigResource.request();
        return SUCCESS;
			}
			return FAIL;
   }	 
	 
	 event void ConfigResource.granted() {
	   if(radioMode == RADIO_MODE_STARTING) {
       call HPLTDA5250Config.reset();   
		   call HPLTDA5250Config.SetRFPower(255);  
       call HPLTDA5250Config.UsePeakDetector();
       call HPLTDA5250Config.SetClockOnDuringPowerDown();
       call HPLTDA5250Config.UseRSSIDataValidDetection(INIT_RSSI_THRESHOLD, TH1_VALUE, TH2_VALUE);
       atomic radioMode = RADIO_MODE_ON;
			 call ConfigResource.release();
			 signal SplitControl.startDone(SUCCESS);
		 }
		 else if(radioMode == RADIO_MODE_STOPPING) {
			 call HPLTDA5250Config.SetClockOffDuringPowerDown();
			 call HPLTDA5250Config.SetSleepMode();
			 atomic radioMode = RADIO_MODE_OFF;
			 call ConfigResource.release();
			 signal SplitControl.stopDone(SUCCESS);
		 }
		 else {
		 }
   }	 
   
   /* radioBusy
    * This function checks whether the radio is busy
    * so as to decide whether it can perform some operation or not.
    */      
   bool radioBusy() {
	   switch(radioMode) {
		   case RADIO_MODE_OFF:
			 case RADIO_MODE_STOPPING:
			 case RADIO_MODE_STARTING:
			 case RADIO_MODE_TRANSITION:
         return TRUE;
       case RADIO_MODE_TX:
       case RADIO_MODE_RX:
       case RADIO_MODE_CCA:
         call DataResource.release();
         return FALSE;
       case RADIO_MODE_ON:
       case RADIO_MODE_SLEEP:
       case RADIO_MODE_TIMER:
       case RADIO_MODE_SELF_POLLING:
			   return FALSE;
		 }
   }
	       
   /**
      Set the mode of the radio 
      The choices are TIMER_MODE, SELF_POLLING_MODE
   */
   async command error_t TDA5250Control.SetTimerMode(float on_time, float off_time) {  
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.SetTimerMode(on_time, off_time);
		 atomic radioMode = RADIO_MODE_TIMER;
		 call ConfigResource.release();
     return SUCCESS;       
   }
   
   async command result_t TDA5250Modes.ResetTimerMode() {
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.ResetTimerMode();
		 atomic radioMode = RADIO_MODE_TIMER;
		 call ConfigResource.release();
     return SUCCESS;        
   }
   
   async command result_t TDA5250Modes.SetSelfPollingMode(float on_time, float off_time) {   
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.SetSelfPollingMode(on_time, off_time);
		 atomic radioMode = RADIO_MODE_SELF_POLLING;
		 call ConfigResource.release();
     return SUCCESS;   
   }
   
   async command result_t TDA5250Modes.ResetSelfPollingMode() {  
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.ResetSelfPollingMode();
		 atomic radioMode = RADIO_MODE_SELF_POLLING;
		 call ConfigResource.release();
     return SUCCESS;    
   }
   
   /** 
      Sets the Potentiometer to a value between 0 and 255 
      for the output power from the transmitter 
   */
   command result_t TDA5250Config.SetRFPower(uint8_t value) {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.SetRFPower(value);
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
   }
   
  command result_t TDA5250Config.UseLowTxPower() {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.UseLowTxPower(); 
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
  }   
  
  command result_t TDA5250Config.LowLNAGain() {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
		 call HPLTDA5250Config.LowLNAGain();  
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;	
  } 
  
  async command result_t TDA5250Config.UseRCIntegrator() {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
     call HPLTDA5250Config.UseRCIntegrator();
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
  }
	
  async command result_t TDA5250Config.UsePeakDetector() {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
     call HPLTDA5250Config.UsePeakDetector();
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
  }
  
  async command result_t TDA5250Config.UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
     call HPLTDA5250Config.UseRSSIDataValidDetection(value, lower_bound, upper_bound);
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
  }  
  
  async command result_t TDA5250Config.SetLowPassFilter(uint8_t data_cutoff) {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
     call HPLTDA5250Config.SetLowPassFilter(data_cutoff);
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS; 
  }
  
  command result_t TDA5250Config.HighLNAGain() {
	   radioMode_t radioModeTemp;
     atomic {
		   if(radioBusy() == FALSE)
			   if(call ConfigResource.immediateRequest() == SUCCESS)
				   radioModeTemp = radioMode;
				   radioMode = RADIO_MODE_TRANSITION;
				 else return FAIL;
			 else return EBUSY;
		 }
     call HPLTDA5250Config.HighLNAGain();
		 atomic radioMode = radioModeTemp;
		 call ConfigResource.release();
     return SUCCESS;
  }
  
  default async event void RadioByteComm.txByteReady(error_t error) {
  }
  default async event void RadioByteComm.rxByteReady(uint8_t data) {
  }
  default async event void TDA5250Control.PWDDDinterrupt() {
  }   
  default event void TDA5250Control.RxModeDone(){
  }
  default event void TDA5250Control.SleepModeDone(){S;
  }
  default event void TDA5250Control.CCAModeDone(){
  }
}
