// $Id: MicaBusC.nc,v 1.1.2.2 2006-01-27 22:04:27 idgay Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A simplistic beginning to providing a standard interface to the mica-family
 * 51-pin bus. Just provides the PW0-PW7 digital I/O pins.
 */

configuration MicaBusC {
  provides {
    interface GeneralIO as PW0;
    interface GeneralIO as PW1;
    interface GeneralIO as PW2;
    interface GeneralIO as PW3;
    interface GeneralIO as PW4;
    interface GeneralIO as PW5;
    interface GeneralIO as PW6;
    interface GeneralIO as PW7;
  }
}
implementation {
  components HplAtm128GeneralIOC as Pins;

  PW0 = Pins.PortC0;
  PW1 = Pins.PortC1;
  PW2 = Pins.PortC2;
  PW3 = Pins.PortC3;
  PW4 = Pins.PortC4;
  PW5 = Pins.PortC5;
  PW6 = Pins.PortC6;
  PW7 = Pins.PortC7;
}
