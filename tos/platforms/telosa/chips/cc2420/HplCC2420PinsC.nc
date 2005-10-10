/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University of California.  
 *  Copyright (c) 2005 Stanford University. 
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: HplCC2420PinsC.nc,v 1.1.2.1 2005-10-10 22:00:43 mturon Exp $
 */

/**
 * Maps the CC2420 pins to the MSP430 for the Telos platform.
 *
 * <pre>
 * $Id: HplCC2420PinsC.nc,v 1.1.2.1 2005-10-10 22:00:43 mturon Exp $
 * </pre>
 *
 * @author Martin Turon
 * @author Joe Polastre
 * @author Phil Levis
 * @date   October 9, 2005
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
  components 
      MSP430GeneralIOC as IO
      , new GeneralIOM() as rCS
      , new GeneralIOM() as rFIFO
      , new GeneralIOM() as rFIFOP
      , new GeneralIOM() as rSFD
      , new GeneralIOM() as rCCA
      , new GeneralIOM() as rVREF
      , new GeneralIOM() as rReset
      ;

  CC_CCA    = rCCA;
  CC_CS     = rCS;
  CC_FIFO   = rFIFO;
  CC_FIFOP  = rFIFOP;
  CC_FIFOP1 = rFIFOP;
  CC_RSTN   = rReset;
  CC_SFD    = rSFD;
  CC_VREN   = rVREF;

  rCCA     -> IO.Port14;
  rCS      -> IO.Port42;
  rFIFO    -> IO.Port13;
  rFIFOP   -> IO.Port10;
  rFIFOP1  -> IO.Port10;
  rReset   -> IO.Port46;
  rSFD     -> IO.Port41;
  rVREF    -> IO.Port45;
}
