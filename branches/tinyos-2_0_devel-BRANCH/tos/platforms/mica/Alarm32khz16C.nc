// $Id: Alarm32khz16C.nc,v 1.1.2.4 2006-02-17 00:26:48 idgay Exp $
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
 * 16-bit 32kHz Alarm component as per TEP102 HAL guidelines. The mica
 * family 32kHz Alarm is built on hardware timer 1, and actually runs at
 * CPU frequency / 256. You can use the MeasureClockC.cyclesPerJiffy()
 * command to figure out the exact frequency.
 *
 * Assumes an ~8MHz CPU clock, replace this component if you are running at
 * a radically different frequency.
 *
 * Upto three of these alarms can be created (one per hardware compare
 * register).
 *
 * @author David Gay <dgay@intel-research.net>
 */

#include "Atm128Timer.h"

generic configuration Alarm32khz16C()
{
  provides interface Alarm<T32khz, uint16_t>;
}
implementation
{
  components HplAtm128Timer1C as HWTimer, Init32khzP,
    new Atm128AlarmC(T32khz, uint16_t, 2) as NAlarm;
  
  enum {
    COMPARE_ID = unique(UQ_TIMER1_COMPARE)
  };

  Alarm = NAlarm;

  NAlarm.HplAtm128Timer -> HWTimer.Timer;
  NAlarm.HplAtm128Compare -> HWTimer.Compare[COMPARE_ID];
}
