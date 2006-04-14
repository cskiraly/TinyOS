// $Id: Alarm32khz32C.nc,v 1.1.2.2 2006-01-27 21:52:11 idgay Exp $
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
 * 32-bit 32kHz Alarm component as per TEP102 HAL guidelines. The mica
 * family 32kHz Alarm is built on hardware timer 1, and actually runs at
 * CPU frequency / 256. You can use the MeasureClockC.cyclesPerJiffy()
 * command to figure out the exact frequency.
 *
 * Upto three of these alarms can be created (one per hardware compare
 * register). Note that creating one of these Alarms consumes a 16-bit
 * 32kHz Alarm (see Alarm32khz16C).
 *
 * @author David Gay <dgay@intel-research.net>
 */

generic configuration Alarm32khz32C()
{
  provides interface Alarm<T32khz, uint32_t>;
}
implementation
{
  components new Alarm32khz16C() as Alarm16, Counter32khz32C as Counter32,
    new TransformAlarmC(T32khz, uint32_t, T32khz, uint16_t, 0)
      as Transform32;

  Alarm = Transform32;
  Transform32.AlarmFrom -> Alarm16;
  Transform32.Counter -> Counter32;
}
