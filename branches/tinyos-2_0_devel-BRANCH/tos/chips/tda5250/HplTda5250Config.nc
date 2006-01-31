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
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-31 12:40:05 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "tda5250Const.h"
/**
 * Configures the Tda5250 radio.
 *
 * This interface provides commands to configure the radio.
 *
 * @author Kevin Klues
 */
interface HplTda5250Config {
   /**
    * Resets all Radio Registers to default values.
    * The default values can be found in tda5250RegDefaults.h
   */
   async command void reset();

   /**
     Set parts of certain registers according to their
     logical function
   */
   async command void UseRCIntegrator();
   async command void UsePeakDetector();
   async command void PowerDown();
   async command void PowerUp();
   async command void RunInTestMode();
   async command void RunInNormalMode();
   async command void ControlRxTxExternally();
   async command void ControlRxTxInternally();
   async command void UseFSK(tda5250_cap_vals_t pos_shift, tda5250_cap_vals_t neg_shift);
   async command void UseASK(tda5250_cap_vals_t pos_shift);
   async command void SetClockOffDuringPowerDown();
   async command void SetClockOnDuringPowerDown();
   async command void InvertData();
   async command void DontInvertData();
   async command void UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound);
   async command void UseVCCDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound);
   async command void UseDataValidDetection();
   async command void UseDataAlwaysValid();
   async command void ADCContinuousMode();
   async command void ADCOneShotMode();
   async command void DataValidContinuousMode();
   async command void DataValidOneShotMode();
   async command void HighLNAGain();
   async command void LowLNAGain();
   async command void EnableReceiverInTimedModes();
   async command void DisableReceiverInTimedModes();
   async command void UseHighTxPower();
   async command void UseLowTxPower();
   async command void TuneNomFreqWithBipolarFET(tda5250_bipolar_fet_ramp_times_t ramp_time, tda5250_cap_vals_t cap_val);
   async command void TuneNomFreqWithFET(tda5250_cap_vals_t cap_val);

   /**
   * Set the mode of the radio to SlaveMode.
   */
   async command void SetSlaveMode();
     
   /**
   * Set the mode of the radio to TimerMode.
   * 
   * @param on_time sets the time (ms) the radio is on.
   * @param off_time sets the time (ms) the radio is off.
   */
   async command void SetTimerMode(float on_time, float off_time);
      
   /**
    * Resets the timers set in SetTimerMode()
    */
   async command void ResetTimerMode();
      
   /**
   * Set the mode of the radio to SetSelfPollingMode.
   *
   * @param on_time sets the time (ms) the radio is on.
   * @param off_time sets the time (ms) the radio is off.
   */
   async command void SetSelfPollingMode(float on_time, float off_time);
      
   /**
    * Reset the timers set in SetSelfPollingMode.
    */
   async command void ResetSelfPollingMode();

   /**
    * Set the contents of the LPF register with the Low pass filter 
    * 
    * @param data_cutoff LowPassFilter characteristics. For recognized values see tda5250Const.h
    */
   async command void SetLowPassFilter(tda5250_data_cutoff_freqs_t data_cutoff);
   
   /**
   * Set the contents of the LPF register with the IQ filter value.
   * 
   * @param iq_cutoff IQ filter characteristics. For recognized values see tda5250Const.h
   */
   async command void SetIQFilter(tda5250_iq_cutoff_freqs_t iq_cutoff);

   /**
    *  Set the on time time of the radio.
    *  This only makes sense when radio is in TIMER or SELF_POLLING Mode.
    * 
    *  @param time (ms) the radio is on.
   */
   async command void SetOnTime_ms(float time);
      
   /**
   *  Set the off time time of the radio.
   *  This only makes sense when radio is in TIMER or SELF_POLLING Mode.
   * 
   *  @param time (ms) the radio is off.
   */
   async command void SetOffTime_ms(float time);

   
   
   /*
   * Initialzes the CLK_DIV so that SetRadioClock(tda5250_clock_out_freqs_t freq)
   * can be used.
   */
   async command void UseSetClock();
   
   /*
   * Sets the CLK_DIV to specified output.
   * Available frequencies given in TDA5250ClockFreq_t struct in tda5250Const.h
   *
   * @param clock frequency (see tda5250.h)
   */
   async command void SetRadioClock(tda5250_clock_out_freqs_t freq);
   
   /*
   * Sets the CLK_DIV to 18Mhz output.
   */
   async command void Use18MHzClock();
   
   /*
   * Sets the CLK_DIV to 32Khz output.
   */
   async command void Use32KHzClock();
   
   /*
   * Sets the CLK_DIV to use window count as output.
   */
   async command void UseWindowCountAsClock();
   


   /**
   * Set the value on the attached Potentiometer
   * for the RF Power setting.
   *
   * @param RF Power.
   */
   command void SetRFPower(uint8_t value);

   /**
   * Sets the RSSI threshold for internal evaluation.
   *
   * @param RSSI threshold value.
   */
   async command void SetRSSIThreshold(uint8_t value);
   
   /** FIXME: doc?
   *        Sets the threshold Values for internal evaluation
   */
   async command void SetVCCOver5Threshold(uint8_t value);
   
   /** FIXME: doc?
   *        Sets the threshold Values for internal evaluation
   */
   async command void SetLowerDataRateThreshold(uint16_t value);
   
   /** FIXME: doc?
   *        Sets the threshold Values for internal evaluation
   */
   async command void SetUpperDataRateThreshold(uint16_t value);

   /*
   * Gets the currnet RSSI value.
   *
   * @return current RSSI
   */
   async command uint8_t GetRSSIValue();
   
   /*
   * FIXME: doc?
   */
   async command uint8_t GetADCSelectFeedbackBit();
   
   /*
     * FIXME: doc?
   */
   async command uint8_t GetADCPowerDownFeedbackBit();
   
   /*
       * FIXME: doc?
   */
   async command bool IsDataRateLessThanLowerThreshold();
   
   /*
         *FIXME: doc?
   */
   async command bool IsDataRateBetweenThresholds();
   
   /*
          *FIXME: doc?
   */
   async command bool IsDataRateLessThanUpperThreshold();
   
   /*
           *FIXME: doc?
   */
   async command bool IsDataRateLessThanHalfOfLowerThreshold();
   
   /*
            *FIXME: doc?
   */
   async command bool IsDataRateBetweenHalvesOfThresholds();
   
   /*
             *FIXME: doc?
   */
   async command bool IsDataRateLessThanHalfOfUpperThreshold();
   
   /*
   * Checks if the current RSSI equals the threshold set 
   * with SetRSSIThreshold(uint8_t value).
   *
   * @return TRUE if RSSI equals the threshhold value
   *         FALSE otherwise.
   */
   async command bool IsRSSIEqualToThreshold();
   
   /*
   * Checks if the current RSSI is graeter than the threshold set 
   * with SetRSSIThreshold(uint8_t value).
   *
   * @return TRUE if RSSI greater than threshhold value
   *         FALSE otherwise.
   */
   async command bool IsRSSIGreaterThanThreshold();

  
   /*
   * Switches the radio to TxMode when in SLAVE_MODE
   */
   async command void SetTxMode();
   
   /*
   * Switches the radio to RxMode when in SLAVE_MODE
   */
   async command void SetRxMode();
   
   /*
   * Switches the radio to SleepMode when in SLAVE_MODE
   */
   async command void SetSleepMode();

   /*
   * Signals that the radio is switched to TxMode.
   */
   async event void SetTxModeDone();
   
   /*
   * Signals that the radio is switched to RxMode.
   */
   async event void SetRxModeDone();
   
   /*
   * Signals that the radio is switched to SleepMode.
   */
   async event void SetSleepModeDone();


   /**
   *  Signals that the RSSI level is stable after
   *  being switched into Rx Mode.
   */
   async event void RSSIStable();

   /**
   * Notification of interrupt when in
   * TimerMode or SelfPollingMode.
   */
   async event void PWDDDInterrupt();
}

