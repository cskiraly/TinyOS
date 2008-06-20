// $Id: CounterMicro32C.nc,v 1.1.2.2.6.2 2006-05-15 19:08:28 klueska Exp $
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
 * 32-bit microsecond Counter component as per TEP102 HAL guidelines. The
 * mica family microsecond clock is built on hardware timer 3, and actually
 * runs at CPU frequency / 8. You can use the MeasureClockC.cyclesPerJiffy() 
 * command to figure out the exact frequency.
 *
 * @author David Gay <dgay@intel-research.net>
 */

#include <MicaTimer.h>

configuration CounterMicro32C
{
  provides interface Counter<TMicro, uint32_t>;
}
implementation
{
  components CounterMicro16C as Counter16, 
    new TransformCounterC(TMicro, uint32_t, TMicro, uint16_t, 0, counter_three_overflow_t)
      as Transform32;

  Counter = Transform32;
  Transform32.CounterFrom -> Counter16;
}