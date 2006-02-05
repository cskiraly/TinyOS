// $Id: CounterMicro32C.nc,v 1.1.2.2 2006-01-27 21:52:11 idgay Exp $
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

configuration CounterMicro32C
{
  provides interface Counter<TMicro, uint32_t>;
}
implementation
{
  components CounterMicro16C as Counter16, 
    new TransformCounterC(TMicro, uint32_t, TMicro, uint16_t, 0, uint16_t)
      as Transform32;

  Counter = Transform32;
  Transform32.CounterFrom -> Counter16;
}
