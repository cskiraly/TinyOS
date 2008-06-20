/* $Id: MotePlatformP.nc,v 1.1.2.2 2005-10-11 22:14:50 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * The micaZ portion of a mica-family initialisation that is
 * mote-specific.
 * 
 * @author David Gay
 */
module MotePlatformP
{
  provides interface Init as PlatformInit;
  uses interface GeneralIO as SerialIdPin;
  uses interface Init as SubInit;
}
implementation {

  command error_t PlatformInit.init() {
    // Pull C I/O port pins low
    PORTC = 0;
    DDRC = 0xff;

    SET_BIT(ASSR, AS0);  // set Timer/Counter0 to use 32,768khz crystal

    // Prevent sourcing current
    call SerialIdPin.makeInput(); 
    call SerialIdPin.clr();

    return call SubInit.init();
  }

  default command error_t SubInit.init() {
    return SUCCESS;
  }
}