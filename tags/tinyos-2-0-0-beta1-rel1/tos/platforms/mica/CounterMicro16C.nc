// $Id: CounterMicro16C.nc,v 1.1.2.3 2006-01-27 21:52:11 idgay Exp $
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
 * 16-bit microsecond Counter component as per TEP102 HAL guidelines. The
 * mica family microsecond clock is built on hardware timer 3, and actually
 * runs at CPU frequency / 8. You can use the MeasureClockC.cyclesPerJiffy() 
 * command to figure out the exact frequency.
 *
 * @author David Gay <dgay@intel-research.net>
 */

configuration CounterMicro16C
{
  provides interface Counter<TMicro, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, InitMicroP,
    new Atm128CounterC(TMicro, uint16_t) as NCounter;
  
  Counter = NCounter;
  NCounter.Timer -> HWTimer;
}
