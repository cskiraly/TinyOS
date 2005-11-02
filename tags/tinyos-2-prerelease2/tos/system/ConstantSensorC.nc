/// $Id: ConstantSensorC.nc,v 1.1.2.2 2005-10-31 20:11:17 scipio Exp $

/*                                                                      tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Simple sensor emulator that just outputs a constant value. 
 *
 * @author Philip Levis
 * @date   Oct 31 2005
 */
  
generic module ConstantSensorC(uint16_t val) { 
  provides interface StdControl;	
  provides interface AcquireData;
}
implementation
{
  command error_t StdControl.start() {
    return SUCCESS;
  }
  command error_t StdControl.stop() {
    return SUCCESS;
  }

  task void senseResult() {
    signal AcquireData.dataReady(val);
  }

  command error_t AcquireData.getData() {
    return post senseResult();
  }
  
}
