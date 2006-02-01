// $Id: Counter32khz16C.nc,v 1.1.2.3 2006-02-01 16:42:54 idgay Exp $
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
 * 16-bit 32kHz Counter component as per TEP102 HAL guidelines. The mica
 * family 32kHz clock is built on hardware timer 1, and actually runs at
 * CPU frequency / 256. You can use the MeasureClockC.cyclesPerJiffy()
 * command to figure out the exact frequency.
 *
 * @author David Gay <dgay@intel-research.net>
 */

configuration Counter32khz16C
{
  provides interface Counter<T32khz, uint16_t>;
}
implementation
{
  components HplAtm128Timer1C as HWTimer, Init32khzP,
    new Atm128CounterC(T32khz, uint16_t) as NCounter;
  
  Counter = NCounter;
  NCounter.Timer -> HWTimer;
}
