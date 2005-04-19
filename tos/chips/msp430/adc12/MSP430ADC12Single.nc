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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-04-19 20:59:37 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
        
includes  MSP430ADC12;
interface MSP430ADC12Single
{     
  /**
    * Binds the interface instance to the values specified in
    * <code>settings</code>. This command must be called once 
    * before the first call to <code>getData</code> or 
    * <code>getDataRepeat</code> is made (a good spot is  
    * StdControl.init). 
    * It can also be used to change settings later on.
    *
    * @return FAIL if interface parameter is out of bounds or
    * conversion in progress for this interface, SUCCESS otherwise
    */
  command result_t bind(MSP430ADC12Settings_t settings);

  /**
    * Initiates one single conversion. After the conversion is 
    * performed the event <code>dataReady</code> is signalled 
    * with the conversion result.
    * If VREF was chosen as reference voltage in <code>bind</code> 
    * and the voltage generator has not yet reached a stable level,
    * <code>MSP430ADC12_DELAYED</code> is returned and the conversion  
    * process starts as soon as VREF becomes stable (max. 17ms).
    *
    * @return MSP430ADC12_FAIL the adc is busy  
    * MSP430ADC12_SUCCESS successfully triggered conversion
    * MSP430ADC12_DELAYED conversion starts as soon as VREF becomes stable.
    */
  async command msp430ADCresult_t getData();

  /**
    * Initiates conversions in repeat mode, ie. continuously.
    * After each conversion is performed an event <code>dataReady</code>
    * is signalled with the conversion result until the eventhandler 
    * returns <code>FAIL</code>.
    * Successive conversions are performed as quickly as possible if
    * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> 
    * define the time between successive conversions in terms of 
    * clock ticks of settings.clockSourceSAMPCON and input divider 
    * settings.clockDivSAMPCON specified in <code>bind()</code>.  
    * If VREF was chosen as reference voltage in <code>bind</code> 
    * and the voltage generator has not yet reached a stable level,
    * <code>MSP430ADC12_DELAYED</code> is returned and the conversion  
    * process starts as soon as VREF becomes stable (max. 17ms).
    *
    * @return MSP430ADC12_FAIL the adc is busy  
    * MSP430ADC12_SUCCESS successfully triggered first conversion
    * MSP430ADC12_DELAYED conversion starts as soon as VREF becomes stable.
    */
  async command msp430ADCresult_t getDataRepeat(uint16_t jiffies);   
  
  /**
    * Reserves the ADC for one single conversion.  If this call  
    * succeeds the next call to <code>getData</code> will also succeed 
    * and the corresponding conversion will then be started with a
    * minimum latency. Until then all other commands will fail.
    *
    * @return SUCCESS reservation successful
    * FAIL otherwise 
    */
  async command result_t reserve();

  /**
    * Reserves the ADC for repeated conversions.  If this call  
    * succeeds the next call to <code>getDataRepeat/code> will also succeed 
    * and the corresponding conversion will then be started with a
    * minimum latency. Until then all other commands will fail.
    *
    * @return SUCCESS reservation successful
    * FAIL otherwise 
    */
  async command result_t reserveRepeat(uint16_t jiffies);

  /**
    * Cancels the reservation made by <code>reserve</code> or
    * <code>reserveRepeat</code>.
    *
    * @return SUCCESS un-reservation successful
    * FAIL no reservation active 
    */
  async command result_t unreserve();

  /**
    * Conversion result from call to <code>getData</code> or 
    * <code>getDataRepeat</code> is ready. In the first case
    * the returned value is ignored, in the second it defines
    * whether any further conversions will be made or not.
    *
    * @param data The conversion result. The lower 12 bits
    * are the actual result and the upper 4 bits are zero.
    *
    * @return SUCCESS continues sampling in repeat mode
    * FAIL stops further conversions in repeat mode 
    */
  async event result_t dataReady(uint16_t data);
}

