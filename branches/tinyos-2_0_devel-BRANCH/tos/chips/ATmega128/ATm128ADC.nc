/// $Id: ATm128ADC.nc,v 1.1.2.3 2005-03-24 08:47:40 husq Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Hu Siquan <husq@xbow.com>
/**
 * Hardware Abstraction Layer interface of Atmega128.
 * Any time only one channel can access ADC, other requests will be blocked.
 */        
interface ATm128ADC
{
	
  /**
   * Initiates an ADC conversion on a given channel.
   *
   * @return SUCCESS if the ADC is free and available to accept the request
   */
  async command result_t getData();
  
  /**
   * Initiates a series of ADC conversions in free running mode. If return SUCCESS from 
   * <code>dataReady()</code> initiates the next conversion, or stop future conversions.
   *
   * @return SUCCESS if the ADC is free and available to accept the request
   */	
  async command result_t getContinuousData();

  /**
    * Reserves the ADC for one single conversion or free running conversions.  
    * If this call succeeds the next call to <code>getData</code> or 
    * <code>getContinuousData/code> will also succeed and the corresponding 
    * conversion will then be started with a minimum latency. Until then all 
    * other commands will fail.
    *
    * @return SUCCESS reservation successful
    * FAIL otherwise 
    */
  async command result_t reserveADC();

  /**
    * Cancels the reservation made by <code>reserve</code> or
    * <code>reserveContinuous</code>.
    *
    * @return SUCCESS un-reservation successful
    * FAIL no reservation active 
    */
  async command result_t unreserve();
  
  /**
   * Indicates a sample has been recorded by the ADC as the result
   * of a <code>getData()</code> command.
   *
   * @param data a 2 byte unsigned data value sampled by the ADC.
   *
   * @return SUCCESS if ready for the next conversion in continuous mode.
   * @return FAIL will stop future continuous sampling.
   * if not in continuous mode, the return code is ignored.
   */	
  async event result_t dataReady(uint16_t data);
}
