// $Id: MeasureClockC.nc,v 1.1.2.4 2006-01-27 23:13:23 idgay Exp $
/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Measure cpu clock frequency at boot time. Provides a command
 * (<code>cyclesPerJiffy</code>) to return the number of cpu cycles per
 * "jiffy"( 1/32768s) and a command (<code>calibrateMicro</code>) to 
 * convert a number of microseconds into "AlarmMicro microseconds".
 * An "AlarmMicro microsecond" is actually 8 cpu cycles (see 
 * AlarmMicro16C and AlarmMicro32C).
 *
 * @author David Gay
 */

#include "scale.h"

module MeasureClockC {
  /* This code MUST be called from PlatformP only, hence the exactlyonce */
  provides interface Init @exactlyonce();

  provides {
    /**
     * Return CPU cycles per 1/32768s.
     * @return CPU cycles.
     */
    command uint16_t cyclesPerJiffy();

    /**
     * Convert n microseconds into a value suitable for use with
     * AlarmMicro16C and AlarmMicro32C Alarms.
     * @return (n + 122) * 244 / cyclesPerJiffy
     */
    command uint32_t calibrateMicro(uint32_t n);
  }
}
implementation 
{
  uint16_t cycles;

  command error_t Init.init() {
    /* Measure clock cycles per Jiffy (1/32768s) */
    /* This code doesn't use the HPL to avoid timing issues when compiling
       with debugging on */
    atomic
      {
	uint8_t now;
	uint16_t start;

	/* Setup timer0 to count 32 jiffies, and timer1 cpu cycles */
	TCCR1B = 1 << CS10;
	ASSR = 1 << AS0;
	TCCR0 = 1 << CS01 | 1 << CS00;

	/* Wait for a jiffy change */
	now = TCNT0;
	while (TCNT0 == now) ;

	/* Read cpu cycles and wait for next jiffy change */
	start = TCNT1;
	now = TCNT0;
	while (TCNT0 == now) ;
	cycles = TCNT1;

	cycles = (cycles - start + 16) >> 5;

	/* Reset to boot state */
	ASSR = TCCR1B = TCCR0 = 0;
	TCNT0 = 0;
	TCNT1 = 0;
      }
    return SUCCESS;
  }

  command uint16_t cyclesPerJiffy() {
    return cycles;
  }

  command uint32_t calibrateMicro(uint32_t n) {
    return scale32(n + 122, 244, cycles);
  }
}
