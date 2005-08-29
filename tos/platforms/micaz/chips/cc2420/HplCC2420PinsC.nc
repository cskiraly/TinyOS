// $Id: HplCC2420PinsC.nc,v 1.1.2.1 2005-08-29 00:54:23 scipio Exp $

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
 *
 * Authors: Alan Broad, Crossbow
 * Date last modified:  $Revision: 1.1.2.1 $
 *
 */

/**
 * Low level hardware access to the CC2420
 * @author Matt Miller
 */

configuration HplCC2420PinsC {
  provides {
    interface GeneralIO as CC_CCA;
    interface GeneralIO as CC_CS;
    interface GeneralIO as CC_FIFO;
    interface GeneralIO as CC_FIFOP;
    interface GeneralIO as CC_FIFOP1;
    interface GeneralIO as CC_RSTN;
    interface GeneralIO as CC_SFD;
    interface GeneralIO as CC_VREN;
    interface GeneralIO as MISO;
    interface GeneralIO as MOSI;
    interface GeneralIO as SPI_SCK;
  }
}
implementation {
  components HplGeneralIOC as IO;
  
  CC_CCA    = IO.PortD6;
  CC_CS     = IO.PortB0;
  CC_FIFO   = IO.PortB7;
  CC_FIFOP  = IO.PortE6;
  CC_FIFOP1 = IO.PortE6;
  CC_RSTN   = IO.PortA6;
  CC_SFD    = IO.PortD4;
  CC_VREN   = IO.PortA5;
  MISO      = IO.PortB3;
  MOSI      = IO.PortB2;
  SPI_SCK   = IO.PortB1;
}
