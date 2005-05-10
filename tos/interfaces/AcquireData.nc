// $Id: AcquireData.nc,v 1.1.2.1 2005-05-10 18:37:28 idgay Exp $

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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Data acquisition interface. See TEP 101.
 * 
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

interface AcquireData { // similar to previous Sensor proposal
  /** Start data acquisition
   *  @return SUCCESS if request accepted, EBUSY if it is refused
   *    'dataReady' or 'error' will be signaled if SUCCESS is returned
   */
  command error_t getData();

  /** Data has been acquired.
   * @param data Acquired value
   *   Values are "left-justified" within each 16-bit integer, i.e., if
   *   the data is acquired with n bits of precision, each value is 
   *   shifted left by 16-n bits.
   */
  event void dataReady(uint16_t data);

  /** Signal that the data acquisition failed
   * @param info error information
   */
  event void error(uint16_t info);
}

