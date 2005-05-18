// $Id: CC2420RadioCaptureSFD.nc,v 1.1.2.2 2005-05-18 05:19:19 jpolastre Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */
configuration CC2420RadioCaptureSFD
{
  provides interface Capture;
}
implementation
{
  components 
      new CaptureM() as SFDM
    , MSP430TimerC
    , MSP430GeneralIOC
    , Counter32khzC
    ;

  Capture = SFDM;
  
  SFDM.LocalTime -> Counter32khzC;
  SFDM.MSP430Control -> MSP430TimerC.ControlB1;
  SFDM.MSP430Capture -> MSP430TimerC.CaptureB1;
  SFDM.MSP430GeneralIO -> MSP430GeneralIOC.Port41;

}

