/// $Id: ATm128ADC.nc,v 1.1.2.4 2005-05-10 18:28:23 idgay Exp $

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
  async command error_t getData();
  
  /**
   * Initiates a series of ADC conversions in free running mode. If return SUCCESS from 
   * <code>dataReady()</code> initiates the next conversion, or stop future conversions.
   *
   * @return SUCCESS if the ADC is free and available to accept the request
   */	
  async command error_t getContinuousData();

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
  async event error_t dataReady(uint16_t data);
}
