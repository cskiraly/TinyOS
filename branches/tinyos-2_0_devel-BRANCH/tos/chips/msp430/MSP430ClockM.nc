//$Id: MSP430ClockM.nc,v 1.1.2.2 2005-02-10 01:07:37 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

includes MSP430Timer;

module MSP430ClockM
{
  provides interface Init;
  provides interface MSP430ClockInit;
  uses interface MSP430Compare as ACLKCompare;
  uses interface MSP430TimerControl as ACLKControl;
}
implementation
{
  MSP430REG_NORACE(IE1);
  MSP430REG_NORACE(TACTL);
  MSP430REG_NORACE(TAIV);
  MSP430REG_NORACE(TBCTL);
  MSP430REG_NORACE(TBIV);

  volatile norace uint16_t m_dco_curr;
  volatile norace uint16_t m_dco_prev;
  volatile norace uint8_t m_aclk_count;

  enum
  {
    ACLK_CALIB_PERIOD = 128,
    ACLK_KHZ = 32,
    TARGET_DCO_KHZ = 4096, // prescribe the cpu clock rate in kHz
    TARGET_DCO_DELTA = (TARGET_DCO_KHZ / ACLK_KHZ) * ACLK_CALIB_PERIOD,
  };

  command void MSP430ClockInit.defaultInitClocks()
  {
    // BCSCTL1
    // .XT2OFF = 1; disable the external oscillator for SCLK and MCLK
    // .XTS = 0; set low frequency mode for LXFT1
    // .DIVA = 0; set the divisor on ACLK to 1
    // .RSEL, do not modify
    BCSCTL1 = XT2OFF | (BCSCTL1 & (RSEL2|RSEL1|RSEL0));

    // BCSCTL2
    // .SELM = 0; select DCOCLK as source for MCLK
    // .DIVM = 0; set the divisor of MCLK to 1
    // .SELS = 0; select DCOCLK as source for SCLK
    // .DIVS = 2; set the divisor of SCLK to 4
    // .DCOR = 0; select internal resistor for DCO
    BCSCTL2 = DIVS1;

    // IE1.OFIE = 0; no interrupt for oscillator fault
    CLR_FLAG( IE1, OFIE );
  }

  command void MSP430ClockInit.defaultInitTimerA()
  {
    TAR = 0;

    // TACTL
    // .TACLGRP = 0; each TACL group latched independently
    // .CNTL = 0; 16-bit counter
    // .TASSEL = 2; source SMCLK = DCO/4
    // .ID = 0; input divisor of 1
    // .MC = 0; initially disabled
    // .TACLR = 0; reset timer A
    // .TAIE = 1; enable timer A interrupts
    TACTL = TASSEL1 | TAIE;
  }

  command void MSP430ClockInit.defaultInitTimerB()
  {
    TBR = 0;

    // TBCTL
    // .TBCLGRP = 0; each TBCL group latched independently
    // .CNTL = 0; 16-bit counter
    // .TBSSEL = 1; source ACLK
    // .ID = 0; input divisor of 1
    // .MC = 0; initially disabled
    // .TBCLR = 0; reset timer B
    // .TBIE = 1; enable timer B interrupts
    TBCTL = TBSSEL0 | TBIE;
  }

  default event void MSP430ClockInit.initClocks()
  {
    call MSP430ClockInit.defaultInitClocks();
  }

  default event void MSP430ClockInit.initTimerA()
  {
    call MSP430ClockInit.defaultInitTimerA();
  }

  default event void MSP430ClockInit.initTimerB()
  {
    call MSP430ClockInit.defaultInitTimerB();
  }


  void startTimerA()
  {
    // TACTL.MC = 2; continuous mode
    TACTL = MC1 | (TACTL & ~(MC1|MC0));
  }

  void stopTimerA()
  {
    //TACTL.MC = 0; stop timer B
    TACTL = TACTL & ~(MC1|MC0);
  }

  void startTimerB()
  {
    // TBCTL.MC = 2; continuous mode
    TBCTL = MC1 | (TBCTL & ~(MC1|MC0));
  }

  void stopTimerB()
  {
    //TBCTL.MC = 0; stop timer B
    TBCTL = TBCTL & ~(MC1|MC0);
  }


  async event void ACLKCompare.fired()
  {
    if( m_aclk_count > 0 )
    {
      m_dco_prev = m_dco_curr;
      m_dco_curr = TAR;
      if( m_aclk_count > 1 )
	call ACLKCompare.setEventFromPrev( ACLK_CALIB_PERIOD );
      m_aclk_count--;
    }
  }

  void set_calib( int calib )
  {
    BCSCTL1 = (BCSCTL1 & ~0x07) | ((calib >> 8) & 0x07);
    DCOCTL = calib & 0xff;
  }

  void test_calib( int calib )
  {
    set_calib( calib );
    m_aclk_count = 2;
    call ACLKCompare.setEventFromNow( ACLK_CALIB_PERIOD );
  }

  uint16_t busywait_delta()
  {
    while( m_aclk_count != 0 ) { }
    return m_dco_curr - m_dco_prev;
  }

  uint16_t test_calib_busywait_delta( int calib )
  {
    test_calib( calib );
    return busywait_delta();
  }

  // busyCalibrateDCO: DESTRUCTIVE TO ALL TIMERS
  void busyCalibrateDCO()
  {
    // --- variables ---
    int calib;
    int step;

    // --- setup ---

    // destructive: force all clocks and timers into a default state
    // (using TimerA2 with ACLK as its source this didn't work, wth)
    m_aclk_count = 0;
    TACTL = TASSEL1 | MC1; // source SMCLK, continuous mode, everything else 0
    TBCTL = TBSSEL0 | MC1;
    CLR_FLAG( IE1, OFIE );
    BCSCTL1 = XT2OFF | RSEL2;
    BCSCTL2 = 0;
    TACCTL0 = 0;
    TACCTL1 = 0;
    TACCTL2 = 0;
    TBCCTL0 = 0;
    TBCCTL1 = 0;
    TBCCTL2 = 0;
    TBCCTL3 = 0;
    TBCCTL4 = 0;
    TBCCTL5 = 0;
    TBCCTL6 = 0;
    SET_FLAG( TBCTL, TBIE ); // enable timer b interrupts
    call ACLKControl.setControlAsCompare();
    call ACLKControl.enableEvents();

    // --- calibrate ---

    // Binary search for RSEL,DCO,DCOMOD.
    // It's okay that RSEL isn't monotonic.

    for( calib=0,step=0x800; step!=0; step>>=1 )
    {
      // if the step is not past the target, commit it
      if( test_calib_busywait_delta(calib|step) <= TARGET_DCO_DELTA )
	calib |= step;
    }

    // --- restore ---

    // disable Timer A and A2
    TACTL = 0;
    TBCTL = 0;
    TBCCTL2 = 0;
  }

  void garnishedBusyCalibrateDCO()
  {
    bool do_disable_interrupts = !are_interrupts_enabled();
    __nesc_enable_interrupt();
    busyCalibrateDCO();
    if(do_disable_interrupts)
      __nesc_disable_interrupt();
  }
    
  command error_t Init.init()
  {
    // Reset timers and clear interrupt vectors
    TACTL = TACLR;
    TBCTL = TBCLR;
    TAIV = 0;
    TBIV = 0;

    garnishedBusyCalibrateDCO();

    atomic
    {
      signal MSP430ClockInit.initClocks();
      signal MSP430ClockInit.initTimerA();
      signal MSP430ClockInit.initTimerB();
      startTimerA();
      startTimerB();
    }

    return SUCCESS;
  }
}

