// $Id: Pot.nc,v 1.1.2.1 2005-05-30 19:32:30 klueska Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  8/20/02
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Kevin Klues -- modified for TinyOS-2.x
 */

interface Pot {
    /** 
     * Initialize the potentiometer and set it to a specified value. 
     * @param initialSetting The initial value for setting of the 
		 * potentiometer
     * @return Returns SUCCESS upon successful initialization. 
     */
  command error_t init(uint8_t initialSetting);

    /**
     * Set the potentiometer value
     * @param setting The new value of the potentiometer. 
     * @return Returns SUCCESS if the setting was successful.  The operation
     * returns FAIL if the component has not been initialized or the desired
     * setting is outside of the valid range. 
     */ 
  async command error_t set(uint8_t setting);

    /** 
     * Increment the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     * @return Returns SUCCESS if the increment was successful. Returns FAIL
     * if the component has not been initialized or if the potentiometer
     * cannot be incremented further. 
     */ 
  async command error_t increase();

    /** 
     * Decrement the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     * @return Returns SUCCESS if the decrement was successful. Returns FAIL
     * if the component has not been initialized or if the potentiometer
     * cannot be decremented further. 
     */ 
  async command error_t decrease();

    /**
     * Return the current setting of the potentiometer. 
     * @return An unsigned 8-bit value denoting the current setting of the
     * potentiometer. 
     */
  async command uint8_t get();
}

