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
 * $Date: 2005-02-09 14:37:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
includes ADCError;
interface ADCMultiple
{
  /**
    * Initiates a series of, i.e. multiple successive conversions. 
    * The length of a series must match and is only bounded by the 
    * size of the buffer. An event <code>dataReady</code> is signalled
    * when the buffer is filled with conversion results. 
    * Successive conversions are performed as quickly as possible.
    *
    * @param buf Buffer to store the conversion results. Ignored
    * if <code>reserve</code> was called successfully before,
    * because then those settings are applicable.
    *
    * @param length The size of the buffer and number of conversions.
    * Ignored if <code>reserve</code> was called successfully before,
    * because then those settings are applicable.
    *
    * @return ADC_SUCCESS if the ADC is free and available 
    * to accept the request, error code otherwise (see ADCHIL.h).
    */
  async command adcresult_t getData(uint16_t *buf, uint16_t length);

  /**
    * Initiates a series of, i.e. multiple successive conversions,
    * in repeat mode, i.e. continuously.
    * After each series of conversions is performed an event 
    * <code>dataReady</code> is signalled with the conversion results.
    * This continues until the eventhandler returns <code>FAIL</code>.
    *
    * @param buf Buffer to store the conversion results. Ignored
    * if <code>reserveContinuous</code> was called successfully before,
    * because then those settings are applicable.
    *
    * @param length The size of the buffer and number of conversions.
    * Ignored if <code>reserveContinuous</code> was called successfully before,
    * because then those settings are applicable.
    *
    * @return ADC_SUCCESS if the ADC is free and available 
    * to accept the request, error code otherwise (see ADCHIL.h).
    */
  async command adcresult_t getDataContinuous(uint16_t *buf, uint16_t length);
    
  /**
    * Reserves the ADC for a series of conversions.  If this call  
    * succeeds the next call to <code>getData</code> will also succeed 
    * and the first corresponding conversion will then be started with a
    * minimum latency.
    *
    * @return ADC_SUCCESS if reservation was successful,
    * error code otherwise (see ADCHIL.h).
    */
  async command adcresult_t reserve(uint16_t *buf, uint16_t length);
  
  /**
    * Reserves the ADC for a series of conversions in repeat mode. If this call  
    * succeeds the next call to <code>getDataRepeat</code> will also succeed 
    * and the first corresponding conversion will then be started with a
    * minimum latency.
    *
    * @return ADC_SUCCESS if reservation was successful,
    * error code otherwise (see ADCHIL.h).
    */
  async command adcresult_t reserveContinuous(uint16_t *buf, uint16_t length);

  /**
    * Cancels a reservation made by <code>reserve</code> or
    * <code>reserveRepeat</code>.
    *
    * @return ADC_SUCCESS if reservation was cancelled successfully,
    * error code otherwise (see ADCHIL.h).
    */
  async command adcresult_t unreserve();
  
  /**
    * Conversion results from call to <code>getData</code> or 
    * <code>getDataContinuous</code> are ready. In the first case
    * the returned value is ignored, in the second it defines
    * whether any further conversions will be made or not.
    *
    * @param result ADC_SUCCESS if the conversions were performed
    * successfully and the results are valid, error code 
    * otherwise (see ADCHIL.h).
    * @param buf The address of the conversion results, identical 
    * to buf passed to <code>getData</code> or 
    * <code>reserveContinuous</code> .
    * @param length Size of the buffer, identical to length passed to
    * <code>getData</code> or <code>reserveContinuous</code> .
    *
    * @return 0 (nullpointer) stops further conversions in continuous mode,
    * otherwise the pointer points to a buffer of the same length 
    * where the next conversion results are to be stored in continuous mode
    * (ignored if not in continuous mode).
    */
  async event uint16_t* dataReady(adcresult_t result, uint16_t *buf, uint16_t length); 
}

