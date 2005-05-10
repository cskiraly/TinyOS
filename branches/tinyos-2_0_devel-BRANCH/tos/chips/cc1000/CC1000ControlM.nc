/* $Id: CC1000ControlM.nc,v 1.1.2.1 2005-05-10 20:53:05 idgay Exp $
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author Philip Buonadonna, Jaein Jeong
 * Revision:  $Revision: 1.1.2.1 $
 */

/**
 * This module provides the CONTROL functionality for the Chipcon1000
 * series radio.  It exports both a standard control interface and a custom
 * interface to control CC1000 operation.
 */
#include "CC1000Const.h"

module CC1000ControlM {
  provides {
    interface CC1000Control;
  }
  uses {
    interface HPLCC1000;
  }
}
implementation
{
  uint32_t gCurrentChannel;
  uint8_t gCurrentParameters[31];

  enum {
    IF = 150000,
    FREQ_MIN = 4194304,
    FREQ_MAX = 16751615
  };

  const_uint32_t fRefTbl[9] = {2457600,
			       2106514,
			       1843200,
			       1638400,
			       1474560,
			       1340509,
			       1228800,
			       1134277,
			       1053257};
  
  const_uint16_t corTbl[9] = {1213,
			      1416,
			      1618,
			      1820,
			      2022,
			      2224,
			      2427,
			      2629,
			      2831};
  
  const_uint16_t fSepTbl[9] = {0x1AA,
			       0x1F1,
			       0x238,
			       0x280,
			       0x2C7,
			       0x30E,
			       0x355,
			       0x39C,
			       0x3E3};
  
  /************************************************************/
  /* Function: chipcon_cal                                    */
  /* Description: places the chipcon radio in calibrate mode  */
  /*                                                          */
  /************************************************************/

  void chipcon_cal() {
    call HPLCC1000.write(CC1K_PA_POW,0x00);  // turn off rf amp
    call HPLCC1000.write(CC1K_TEST4,0x3f);   // chip rate >= 38.4kb

    // RX - configure main freq A
    call HPLCC1000.write(CC1K_MAIN,
			 ((1<<CC1K_TX_PD) | (1<<CC1K_RESET_N)));
    //uwait(2000);

    // start cal
    call HPLCC1000.write(CC1K_CAL,
			 ((1<<CC1K_CAL_START) | 
			  (1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
#if 0
    for (i=0;i<34;i++)  // need 34 ms delay
      uwait(1000);
#endif
    while (((call HPLCC1000.read(CC1K_CAL)) & (1<<CC1K_CAL_COMPLETE)) == 0);

    //exit cal mode
    call HPLCC1000.write(CC1K_CAL,
			 ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));


    // TX - configure main freq B
    call HPLCC1000.write(CC1K_MAIN,
			 ((1<<CC1K_RXTX) | (1<<CC1K_F_REG) | (1<<CC1K_RX_PD) | 
			  (1<<CC1K_RESET_N)));
    // Set TX current
    call HPLCC1000.write(CC1K_CURRENT,gCurrentParameters[29]);
    call HPLCC1000.write(CC1K_PA_POW,0x00);
    //uwait(2000);

    // start cal
    call HPLCC1000.write(CC1K_CAL,
			 ((1<<CC1K_CAL_START) | 
			  (1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
#if 0
    for (i=0;i<28;i++)  // need 28 ms delay
      uwait(1000);
#endif
    while (((call HPLCC1000.read(CC1K_CAL)) & (1<<CC1K_CAL_COMPLETE)) == 0);

    //exit cal mode
    call HPLCC1000.write(CC1K_CAL,
			 ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
    
    //uwait(200);
  }

  void cc1000SetFreq() {
    uint8_t i;
    // FREQA, FREQB, FSEP, CURRENT(RX), FRONT_END, POWER, PLL
    for (i = 1;i < 0x0d;i++) {
      call HPLCC1000.write(i,gCurrentParameters[i]);
    }

    // MATCH
    call HPLCC1000.write(CC1K_MATCH,gCurrentParameters[0x12]);

    chipcon_cal();
  }

  void cc1000SetModem() {
    call HPLCC1000.write(CC1K_MODEM2,gCurrentParameters[0x0f]);
    call HPLCC1000.write(CC1K_MODEM1,gCurrentParameters[0x10]);
    call HPLCC1000.write(CC1K_MODEM0,gCurrentParameters[0x11]);
  }

  /*
   * cc1000ComputeFreq(uint32_t desiredFreq);
   *
   * Compute an achievable frequency and the necessary CC1K parameters from
   * a given desired frequency (Hz). The function returns the actual achieved
   * channel frequency in Hz.
   *
   * This routine assumes the following:
   *  - Crystal Freq: 14.7456 MHz
   *  - LO Injection: High
   *  - Separation: 64 KHz
   *  - IF: 150 KHz
   * 
   * Approximate costs for this function:
   *  - ~870 bytes FLASH
   *  - ~32 bytes RAM
   *  - 9400 cycles
   */
  uint32_t cc1000ComputeFreq(uint32_t desiredFreq) {
    uint32_t ActualChannel = 0;
    uint32_t RXFreq = 0, TXFreq = 0;
    int32_t Offset = 0x7fffffff;
    uint16_t FSep = 0;
    uint8_t RefDiv = 0;
    uint8_t i;

    for (i = 0; i < 9; i++) {

      uint32_t NRef = ((desiredFreq + IF));
      uint32_t FRef = read_uint32_t(&fRefTbl[i]);
      uint32_t Channel = 0;
      uint32_t RXCalc = 0, TXCalc = 0;
      int32_t  diff;

      NRef = ((desiredFreq + IF) << 2) / FRef;
      if (NRef & 0x1) {
 	NRef++;
      }

      if (NRef & 0x2) {
	RXCalc = 16384 >> 1;
	Channel = FRef >> 1;
      }

      NRef >>= 2;

      RXCalc += (NRef * 16384) - 8192;
      if ((RXCalc < FREQ_MIN) || (RXCalc > FREQ_MAX)) 
	continue;
    
      TXCalc = RXCalc - read_uint16_t(&corTbl[i]);
      if ((TXCalc < FREQ_MIN) || (TXCalc > FREQ_MAX)) 
	continue;

      Channel += (NRef * FRef);
      Channel -= IF;

      diff = Channel - desiredFreq;
      if (diff < 0)
	diff = 0 - diff;

      if (diff < Offset) {
	RXFreq = RXCalc;
	TXFreq = TXCalc;
	ActualChannel = Channel;
	FSep = read_uint16_t(&fSepTbl[i]);
	RefDiv = i + 6;
	Offset = diff;
      }

    }

    if (RefDiv != 0) {
      // FREQA
      gCurrentParameters[0x3] = (uint8_t)((RXFreq) & 0xFF);  // LSB
      gCurrentParameters[0x2] = (uint8_t)((RXFreq >> 8) & 0xFF);
      gCurrentParameters[0x1] = (uint8_t)((RXFreq >> 16) & 0xFF);  // MSB
      // FREQB
      gCurrentParameters[0x6] = (uint8_t)((TXFreq) & 0xFF); // LSB
      gCurrentParameters[0x5] = (uint8_t)((TXFreq >> 8) & 0xFF);
      gCurrentParameters[0x4] = (uint8_t)((TXFreq >> 16) & 0xFF);  // MSB
      // FSEP
      gCurrentParameters[0x8] = (uint8_t)((FSep) & 0xFF);  // LSB
      gCurrentParameters[0x7] = (uint8_t)((FSep >> 8) & 0xFF); //MSB

      if (ActualChannel < 500000000) {
	if (ActualChannel < 400000000) {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((9 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((4 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	// FRONT_END
	gCurrentParameters[0xa] = (1 << CC1K_IF_RSSI); 
	// MATCH
	gCurrentParameters[0x12] = (7 << CC1K_RX_MATCH);
      }
      else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (3 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((15 << CC1K_VCO_CURRENT) | (3 << CC1K_PA_DRIVE));

	// FRONT_END
	gCurrentParameters[0xa] = ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | 
				 (1<<CC1K_IF_RSSI));
	// MATCH
	gCurrentParameters[0x12] = (2 << CC1K_RX_MATCH);

      }
      // PLL
      gCurrentParameters[0xc] = (RefDiv << CC1K_REFDIV);
    }

    gCurrentChannel = ActualChannel;
    return ActualChannel;
  }

  command void CC1000Control.init() {
    call HPLCC1000.init();

    // wake up xtal and reset unit
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD))); 
    // clear reset.
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N))); 
    // reset wait time
    uwait(2000);        

    // Set default parameter values
    // POWER 0dbm
    gCurrentParameters[0xb] = ((8 << CC1K_PA_HIGHPOWER) | (0 << CC1K_PA_LOWPOWER)); 
    call HPLCC1000.write(CC1K_PA_POW, gCurrentParameters[0xb]);

    // LOCK Manchester Violation default
    gCurrentParameters[0xd] = (9 << CC1K_LOCK_SELECT);
    call HPLCC1000.write(CC1K_LOCK_SELECT, gCurrentParameters[0xd]);

    // Default modem values = 19.2 Kbps (38.4 kBaud), Manchester encoded
    // MODEM2
    gCurrentParameters[0xf] = 0;
    //call HPLCC1000.write(CC1K_MODEM2,gCurrentParameters[0xf]);
    // MODEM1
    gCurrentParameters[0x10] = ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | 
				(3<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N));
    //call HPLCC1000.write(CC1K_MODEM1,gCurrentParameters[0x10]);
    // MODEM0
    gCurrentParameters[0x11] = ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | 
				(1<<CC1K_XOSC_FREQ));
    //call HPLCC1000.write(CC1K_MODEM0,gCurrentParameters[0x11]);

    cc1000SetModem();
    // FSCTRL
    gCurrentParameters[0x13] = (1 << CC1K_FS_RESET_N);
    call HPLCC1000.write(CC1K_FSCTRL,gCurrentParameters[0x13]);

    // HIGH Side LO
    gCurrentParameters[0x1e] = TRUE;


    // Program registers w/ default freq and calibrate
#ifdef CC1K_DEF_FREQ
    call CC1000Control.tuneManual(CC1K_DEF_FREQ);
#else
    call CC1000Control.tunePreset(CC1K_DEF_PRESET);     // go to default tune frequency
#endif
  }



  command void CC1000Control.tunePreset(uint8_t freq) {
    int i;

    for (i=1;i < 31 /*0x14*/;i++) {
      //call HPLCC1000.write(i,PRG_RDB(&CC1K_Params[freq][i]));
      gCurrentParameters[i] = read_uint8_t(&CC1K_Params[freq][i]);
    }
    cc1000SetFreq();
  }

  command uint32_t CC1000Control.tuneManual(uint32_t DesiredFreq) {
    uint32_t actualFreq;

    actualFreq = cc1000ComputeFreq(DesiredFreq);

    cc1000SetFreq();

    return actualFreq;
  }

  async command void CC1000Control.txMode() {
    // MAIN register to TX mode
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RXTX) | (1<<CC1K_F_REG) | (1<<CC1K_RX_PD) | 
			   (1<<CC1K_RESET_N)));
    // Set the TX mode VCO Current
    call HPLCC1000.write(CC1K_CURRENT,gCurrentParameters[29]);
    uwait(250);
    call HPLCC1000.write(CC1K_PA_POW,gCurrentParameters[0xb] /*rfpower*/);
    uwait(20);
  }

  async command void CC1000Control.rxMode() {
    // MAIN register to RX mode
    // Powerup Freqency Synthesizer and Receiver
    call HPLCC1000.write(CC1K_CURRENT,gCurrentParameters[0x09]);
    call HPLCC1000.write(CC1K_PA_POW,0x00); // turn off power amp
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_TX_PD) | (1<<CC1K_RESET_N)));
    // Sex the RX mode VCO Current
    uwait(125);
  }

  async command void CC1000Control.biasOff() {
    // MAIN register to SLEEP mode
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));
  }

  async command void CC1000Control.biasOn() {
    //call CC1000Control.RxMode();
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | 
			   (1<<CC1K_RESET_N)));
    
    //uwait(200 /*500*/);
  }


  async command void CC1000Control.off() {
    // MAIN register to power down mode. Shut everything off
    call HPLCC1000.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_CORE_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));

    call HPLCC1000.write(CC1K_PA_POW,0x00);  // turn off rf amp
  }

  async command void CC1000Control.on() {
    // wake up xtal osc
    call HPLCC1000.write(CC1K_MAIN,
			 ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			  (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			  (1<<CC1K_RESET_N)));

    //uwait(2000);
    //call CC1000Control.RxMode();
  }


  command void CC1000Control.setRFPower(uint8_t power) {
    gCurrentParameters[0xb] = power;
    //call HPLCC1000.write(CC1K_PA_POW,rfpower); // Set power amp value
  }

  command uint8_t CC1000Control.getRFPower() {
    return gCurrentParameters[0xb];
  }

  command void CC1000Control.selectLock(uint8_t Value) {
    //LockVal = Value;
    gCurrentParameters[0xd] = (Value << CC1K_LOCK_SELECT);
    call HPLCC1000.write(CC1K_LOCK,(Value << CC1K_LOCK_SELECT));
  }

  command uint8_t CC1000Control.getLock() {
    uint8_t retVal;
    retVal = (uint8_t)call HPLCC1000.getLOCK(); 
    return retVal;
  }

  command bool CC1000Control.getLOStatus() {
    return gCurrentParameters[0x1e];
  }
}


