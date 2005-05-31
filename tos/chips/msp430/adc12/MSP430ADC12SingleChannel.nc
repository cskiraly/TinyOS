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
 * $Date: 2005-05-31 00:10:08 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
includes MSP430ADC12;
interface MSP430ADC12SingleChannel 
{   
  /* Interface for ADC12 on MSP430. See also TEP 101. */  
  
  /* An application needs to implement an event handler for the
   * MSP430ADC12SingleChannel.getConfigurationData() event. This event 
   * handler MUST return the configuration data for the channel
   * the application wants to sample. The event MAY be signalled
   * multiple times by HAL1 and the application MUST always return  
   * the same configuration data. 
   * (see MSP430ADC12.h for a macro to create 
   * msp430adc12_channel_config_t in a convenient way).
   */
  async event msp430adc12_channel_config_t getConfigurationData();

  /*
   * Starts a single conversion. If successful an event singleDataReady()
   * will be signalled with the conversion result.
   * Check MSP430ADC12.h for msp430adc12_result_t definition.  
   */
  async command msp430adc12_result_t getSingleData();

  /*
   * Starts a single conversion in repeat mode. If successful the event 
   * singleDataReady() will be signalled repeatedly with the conversion results,
   * until the application returns FAIL in the event handler.
   * Successive conversions are performed as quickly as possible if
   * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> 
   * define the time between successive conversions in terms of 
   * clock ticks of "clockSourceSAMPCON" and input divider 
   * "clockDivSAMPCON" specified in msp430adc12_channel_config_t
   * (see <code>getConfigurationData()</code> above).
   * Check MSP430ADC12.h for msp430adc12_result_t definition.  
   */
  async command msp430adc12_result_t getSingleDataRepeat(uint16_t jiffies);   

 /**
   * Starts a series of, i.e. multiple successive conversions. 
   * The size of a series must match and is only bounded by the 
   * size of the buffer. The event <code>multipleDataReady</code>
   * is signalled after the buffer is filled with conversion results. 
   * Successive conversions are performed as quickly as possible if
   * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> 
   * define the time between successive conversions in terms of 
   * clock ticks of "clockSourceSAMPCON" and input divider 
   * "clockDivSAMPCON" specified in msp430adc12_channel_config_t
   * (see <code>getConfigurationData()</code> above).
   * Check MSP430ADC12.h for msp430adc12_result_t definition. 
  */ 
  async command msp430adc12_result_t getMultipleData(uint16_t *buf, 
                               uint16_t length, uint16_t jiffies);

 /**
   * Starts a series of, i.e. multiple successive conversions in
   * repeat mode. The size of a series, <code>length</code>,
   * must be <= 16. 
   * The event <code>multipleDataReady</code> is signalled 
   * with conversion results per series until the application 
   * returns a null pointer in the event handler.
   * Successive conversions are performed as quickly as possible if
   * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> 
   * define the time between successive conversions in terms of 
   * clock ticks of "clockSourceSAMPCON" and input divider 
   * "clockDivSAMPCON" specified in msp430adc12_channel_config_t
   * (see <code>getConfigurationData()</code> above).
   * Check MSP430ADC12.h for msp430adc12_result_t definition. 
  */ 
  async command msp430adc12_result_t getMultipleDataRepeat(uint16_t *buf, 
                               uint8_t length, uint16_t jiffies);
                      
 /**
   * Data from call to getSingleData() or getSingleDataRepeat() 
   * is ready. In the first case the return value is ignored,
   * in the second it defines whether another conversion takes
   * place (SUCCESS) or not (FAIL).
   */  
  async event result_t singleDataReady(uint16_t data);

 /**
   * Data from call to getMultipleData() or getMultipleDataRepeat() 
   * is ready. In the first case the return value is ignored,
   * in the second it points to a buffer of size <code>length</code>
   * to store the next <code>length</code> results.
   */    
  async event uint16_t* multipleDataReady(uint16_t *buf, uint16_t length);
}

