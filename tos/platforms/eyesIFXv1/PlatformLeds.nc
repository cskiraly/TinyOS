// $Id: PlatformLeds.nc,v 1.1.2.1 2005-03-16 19:01:05 vlahan Exp $

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
 * @author Vlado Handziski (modifications for eyesIFX)
 */
includes hardware;

configuration PlatformLeds
{
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
  provides interface GeneralIO as Led3;
}
implementation
{
  components 
    MSP430GeneralIOC
    , new GeneralIOM() as Led0Impl
    , new GeneralIOM() as Led1Impl
    , new GeneralIOM() as Led2Impl
    , new GeneralIOM() as Led3Impl
    ;

  Led0 = Led1Impl.IO;
  Led0Impl.MSPIO -> MSP430GeneralIOC.Port50;

  Led1 = Led1Impl.IO;
  Led1Impl.MSPIO -> MSP430GeneralIOC.Port51;

  Led2 = Led2Impl.IO;
  Led2Impl.MSPIO -> MSP430GeneralIOC.Port52;

  Led3 = Led3Impl.IO;
  Led3Impl.MSPIO -> MSP430GeneralIOC.Port53;

}

