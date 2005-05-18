/* $Id: MotePlatformM.nc,v 1.1.2.1 2005-05-18 23:28:14 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The porttion of a mica-family initialisation that is mote-specific.
 * 
 * @author David Gay
 */
module MotePlatformM
{
  provides interface Init as PlatformInit;
  uses interface GeneralIO as SerialIdPin;
}
implementation {

  command error_t PlatformInit.init() {
    // Pull C I/O port pins low
    PORTC = 0;
    DDRC = 0xff;

    // Prevent sourcing current
    call SerialIdPin.makeInput(); 
    call SerialIdPin.clr();

    return SUCCESS;
  }
}
