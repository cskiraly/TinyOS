module MeasureClockC {
  /* This code MUST be called from PlatformP only, hence the exactlyonce */
  provides interface Init @exactlyonce();

  provides command uint16_t cyclesPerJiffy();
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
}
