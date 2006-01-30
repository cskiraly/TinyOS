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
 * $Revision: 1.1.2.3 $
 * $Date: 2006-01-30 17:37:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
  
#include <Msp430Adc12.h>
interface Msp430Adc12SingleChannel 
{   

  /** 
   * 
   * Samples an ADC channel. If MSP430ADC12_SUCCESS or MSP430ADC12_DELAYED is
   * returned, an event singleDataReady() will be signalled with the conversion
   * result. Otherwise singleDataReady() will not be signalled.
   *
   * @return Whether the request succeeded.
   */
  async command error_t getSingleData( const
      msp430adc12_channel_config_t *config);

  /**
   * 
   * Samples an ADC channel in repeat mode. If MSP430ADC12_SUCCESS or
   * MSP430ADC12_DELAYED is returned, an event singleDataReady() will be
   * signalled repeatedly with the conversion results, until the client returns
   * FAIL in the event handler. Otherwise singleDataReady() will not be
   * signalled. Successive conversions are performed as quickly as possible if
   * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> define
   * the time between successive conversions in terms of clock ticks of
   * "clockSourceSAMPCON" and input divider "clockDivSAMPCON" as specified in
   * the <code>config</code> parameter.
   * 
   * @return Whether the request succeeded.
   */
  async command error_t getSingleDataRepeat( const
      msp430adc12_channel_config_t *config, uint16_t jiffies);

 /** 
  *
  * Starts multiple successive conversions for the same ADC channel.  The
  * number of requested samples must match and is only bounded by the size of
  * the buffer.  If MSP430ADC12_SUCCESS or MSP430ADC12_DELAYED is returned, the
  * event <code>multipleDataReady</code> is signalled after the buffer is
  * filled with conversion results. Otherwise <code>multipleDataReady()</code>
  * will not be signalled.  Successive conversions are performed as quickly as
  * possible if <code>jiffies</code> equals zero.  Otherwise
  * <code>jiffies</code> define the time between successive conversions in
  * terms of clock ticks of "clockSourceSAMPCON" and input divider
  * "clockDivSAMPCON" as specified in the <code>config</code> parameter.
  *
  * @return Whether the request succeeded.
  */ 
  async command error_t getMultipleData( const
      msp430adc12_channel_config_t *config, uint16_t *buf, uint16_t length,
      uint16_t jiffies);

 /** 
  *
  * Starts multiple successive conversions in repeat mode. The number of
  * requested samples must be <= 16.   If MSP430ADC12_SUCCESS or
  * MSP430ADC12_DELAYED is returned, the event <code>multipleDataReady</code>
  * is signalled with conversion results per series until the application
  * returns a null pointer in the event handler. Otherwise
  * <code>multipleDataReady()</code> will not be signalled. Successive
  * conversions are performed as quickly as possible if <code>jiffies</code>
  * equals zero.  Otherwise <code>jiffies</code> define the time between
  * successive conversions in terms of clock ticks of "clockSourceSAMPCON" and
  * input divider "clockDivSAMPCON" as specified in the <code>config</code>
  * parameter.
  *
  * @return Whether the request succeeded.
  */ 
  async command error_t getMultipleDataRepeat( const
      msp430adc12_channel_config_t *config, uint16_t *buf, uint8_t length,
      uint16_t jiffies);

 /**
   * Data from call to getSingleData() or getSingleDataRepeat() 
   * is ready. In the first case the return value is ignored,
   * in the second it defines whether another conversion takes
   * place (SUCCESS) or not (FAIL).
   */  
  async event error_t singleDataReady(uint16_t data);

 /**
   * Data from call to getMultipleData() or getMultipleDataRepeat() 
   * is ready. In the first case the return value is ignored,
   * in the second it points to a buffer of size <code>length</code>
   * to store the next conversion results.
   */    
  async event uint16_t* multipleDataReady(uint16_t *buf, uint16_t length);
}

