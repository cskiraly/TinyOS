// $Id: CC2420ControlM.nc,v 1.1.2.5 2005-05-18 19:04:45 jpolastre Exp $
/*
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
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.5 $
 *
 * This module provides the CONTROL functionality for the 
 * Chipcon2420 series radio. It exports both a standard control 
 * interface and a custom interface to control CC2420 operation.
 */

includes byteorder;

module CC2420ControlM {
  provides {
    interface Init;
    interface SplitControl;
    interface CC2420Control;
  }
  uses {
    interface Init as HPLChipconInit;
    interface StdControl as HPLChipconControl;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420RAM as HPLChipconRAM;

    interface Interrupt as CCA;
    interface GeneralIO as RadioReset;
    interface GeneralIO as RadioVREF;
  }
}
implementation
{

  enum {
    IDLE_STATE = 0,
    INIT_STATE,
    INIT_STATE_DONE,
    START_STATE,
    START_STATE_DONE,
    STOP_STATE,
  };

  uint8_t state = 0;
  norace uint16_t gCurrentParameters[14];

   /************************************************************************
   * SetRegs
   *  - Configure CC2420 registers with current values
   *  - Readback 1st register written to make sure electrical connection OK
   *************************************************************************/
  bool SetRegs(){
    uint16_t data;
	      
    call HPLChipcon.write(CC2420_MAIN,gCurrentParameters[CP_MAIN]);   		    
    call HPLChipcon.write(CC2420_MDMCTRL0, gCurrentParameters[CP_MDMCTRL0]);
    data = call HPLChipcon.read(CC2420_MDMCTRL0);
    if (data != gCurrentParameters[CP_MDMCTRL0]) return FALSE;
    
    call HPLChipcon.write(CC2420_MDMCTRL1, gCurrentParameters[CP_MDMCTRL1]);
    call HPLChipcon.write(CC2420_RSSI, gCurrentParameters[CP_RSSI]);
    call HPLChipcon.write(CC2420_SYNCWORD, gCurrentParameters[CP_SYNCWORD]);
    call HPLChipcon.write(CC2420_TXCTRL, gCurrentParameters[CP_TXCTRL]);
    call HPLChipcon.write(CC2420_RXCTRL0, gCurrentParameters[CP_RXCTRL0]);
    call HPLChipcon.write(CC2420_RXCTRL1, gCurrentParameters[CP_RXCTRL1]);
    call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);

    call HPLChipcon.write(CC2420_SECCTRL0, gCurrentParameters[CP_SECCTRL0]);
    call HPLChipcon.write(CC2420_SECCTRL1, gCurrentParameters[CP_SECCTRL1]);
    call HPLChipcon.write(CC2420_IOCFG0, gCurrentParameters[CP_IOCFG0]);
    call HPLChipcon.write(CC2420_IOCFG1, gCurrentParameters[CP_IOCFG1]);

    call HPLChipcon.cmd(CC2420_SFLUSHTX);    //flush Tx fifo
    call HPLChipcon.cmd(CC2420_SFLUSHRX);
 
    return TRUE;
  
  }

  task void taskStopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  task void PostOscillatorOn() {
    //set freq, load regs
    SetRegs();
    call CC2420Control.setShortAddress(TOS_LOCAL_ADDRESS);
    call CC2420Control.TuneManual(((gCurrentParameters[CP_FSCTRL] >> CC2420_FSCTRL_FREQ) & 0x1FF) + 2048);
    atomic state = START_STATE_DONE;
    signal SplitControl.startDone(SUCCESS);
  }

  /*************************************************************************
   * Init CC2420 radio:
   *
   *************************************************************************/
  command error_t Init.init() {

    uint8_t _state = FALSE;

    atomic {
      if (state == IDLE_STATE) {
	state = INIT_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call HPLChipconInit.init();
  
    // Set default parameters
    gCurrentParameters[CP_MAIN] = 0xf800;
    gCurrentParameters[CP_MDMCTRL0] = ((0 << CC2420_MDMCTRL0_ADRDECODE) | 
       (2 << CC2420_MDMCTRL0_CCAHIST) | (3 << CC2420_MDMCTRL0_CCAMODE)  | 
       (1 << CC2420_MDMCTRL0_AUTOCRC) | (2 << CC2420_MDMCTRL0_PREAMBL));

    gCurrentParameters[CP_MDMCTRL1] = 20 << CC2420_MDMCTRL1_CORRTHRESH;

    gCurrentParameters[CP_RSSI] =     0xE080;
    gCurrentParameters[CP_SYNCWORD] = 0xA70F;
    gCurrentParameters[CP_TXCTRL] = ((1 << CC2420_TXCTRL_BUFCUR) | 
       (1 << CC2420_TXCTRL_TURNARND) | (3 << CC2420_TXCTRL_PACUR) | 
       (1 << CC2420_TXCTRL_PADIFF) | (CC2420_DEF_RFPOWER << CC2420_TXCTRL_PAPWR));

    gCurrentParameters[CP_RXCTRL0] = ((1 << CC2420_RXCTRL0_BUFCUR) | 
       (2 << CC2420_RXCTRL0_MLNAG) | (3 << CC2420_RXCTRL0_LOLNAG) | 
       (2 << CC2420_RXCTRL0_HICUR) | (1 << CC2420_RXCTRL0_MCUR) | 
       (1 << CC2420_RXCTRL0_LOCUR));

    gCurrentParameters[CP_RXCTRL1]  = ((1 << CC2420_RXCTRL1_LOLOGAIN) | 
       (1 << CC2420_RXCTRL1_HIHGM) |  (1 << CC2420_RXCTRL1_LNACAP) | 
       (1 << CC2420_RXCTRL1_RMIXT) |  (1 << CC2420_RXCTRL1_RMIXV)  | 
       (2 << CC2420_RXCTRL1_RMIXCUR));

    gCurrentParameters[CP_FSCTRL]   = ((1 << CC2420_FSCTRL_LOCK) | 
       ((357+5*(CC2420_DEF_CHANNEL-11)) << CC2420_FSCTRL_FREQ));

    gCurrentParameters[CP_SECCTRL0] = ((1 << CC2420_SECCTRL0_CBCHEAD) |
       (1 << CC2420_SECCTRL0_SAKEYSEL)  | (1 << CC2420_SECCTRL0_TXKEYSEL) | 
       (1 << CC2420_SECCTRL0_SECM));

    gCurrentParameters[CP_SECCTRL1] = 0;
    gCurrentParameters[CP_BATTMON]  = 0;

    // set fifop threshold to greater than size of tos msg, 
    // fifop goes active at end of msg
    gCurrentParameters[CP_IOCFG0]   = (((127) << CC2420_IOCFG0_FIFOTHR) | 
        (1 <<CC2420_IOCFG0_FIFOPPOL)) ;

    gCurrentParameters[CP_IOCFG1]   =  0;

    atomic state = INIT_STATE_DONE;
    return SUCCESS;
  }


  command error_t SplitControl.stop() {
    error_t ok;
    uint8_t _state = FALSE;

    atomic {
      if (state == START_STATE_DONE) {
	state = STOP_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call HPLChipcon.cmd(CC2420_SXOSCOFF); 
    ok = call CCA.disable();
    ok &= call HPLChipconControl.stop();

    call RadioReset.clr();
    ok &= call CC2420Control.VREFOff();
    call RadioReset.set();

    if (ok)
      post taskStopDone();
    
    atomic state = INIT_STATE_DONE;
    return ok;
  }

/******************************************************************************
 * Start CC2420 radio:
 * -Turn on 1.8V voltage regulator, wait for power-up, 0.6msec
 * -Release reset line
 * -Enable CC2420 crystal,          wait for stabilization, 0.9 msec
 *
 ******************************************************************************/

  command error_t SplitControl.start() {
    error_t status;
    uint8_t _state = FALSE;

    atomic {
      if (state == INIT_STATE_DONE) {
	state = START_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call HPLChipconControl.start();
    //turn on power
    call CC2420Control.VREFOn();
    // toggle reset
    call RadioReset.clr();
    TOSH_wait();
    call RadioReset.set();
    TOSH_wait();
    // turn on crystal, takes about 860 usec, 
    // chk CC2420 status reg for stablize
    status = call CC2420Control.OscillatorOn();

    return status;
  }

  /*************************************************************************
   * TunePreset
   * -Set CC2420 channel
   * Valid channel values are 11 through 26.
   * The channels are calculated by:
   *  Freq = 2405 + 5(k-11) MHz for k = 11,12,...,26
   * chnl requested 802.15.4 channel 
   * return Status of the tune operation
   *************************************************************************/
  command error_t CC2420Control.TunePreset(uint8_t chnl) {
    int fsctrl;
    uint8_t status;
    
    fsctrl = 357 + 5*(chnl-11);
    gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
    status = call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);
    // if the oscillator is started, recalibrate for the new frequency
    // if the oscillator is NOT on, we should not transition to RX mode
    if (status & (1 << CC2420_XOSC16M_STABLE))
      call HPLChipcon.cmd(CC2420_SRXON);
    return SUCCESS;
  }

  /*************************************************************************
   * TuneManual
   * Tune the radio to a given frequency. Frequencies may be set in
   * 1 MHz steps between 2400 MHz and 2483 MHz
   * 
   * Desiredfreq The desired frequency, in MHz.
   * Return Status of the tune operation
   *************************************************************************/
  command error_t CC2420Control.TuneManual(uint16_t DesiredFreq) {
    int fsctrl;
    uint8_t status;
   
    fsctrl = DesiredFreq - 2048;
    gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
    status = call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);
    // if the oscillator is started, recalibrate for the new frequency
    // if the oscillator is NOT on, we should not transition to RX mode
    if (status & (1 << CC2420_XOSC16M_STABLE))
      call HPLChipcon.cmd(CC2420_SRXON);
    return SUCCESS;
  }

  /*************************************************************************
   * Get the current frequency of the radio
   */
  command uint16_t CC2420Control.GetFrequency() {
    return ((gCurrentParameters[CP_FSCTRL] >> CC2420_FSCTRL_FREQ) & 0x1FF) + 2048;
  }

  /*************************************************************************
   * Get the current channel of the radio
   */
  command uint8_t CC2420Control.GetPreset() {
    uint16_t _freq = ((gCurrentParameters[CP_FSCTRL] >> CC2420_FSCTRL_FREQ) & 0x1FF);
    _freq = (_freq - 357)/5;
    _freq = _freq + 11;
    return _freq;
  }

  /*************************************************************************
   * TxMode
   * Shift the CC2420 Radio into transmit mode.
   * return SUCCESS if the radio was successfully switched to TX mode.
   *************************************************************************/
  async command error_t CC2420Control.TxMode() {
    call HPLChipcon.cmd(CC2420_STXON);
    return SUCCESS;
  }

  /*************************************************************************
   * TxModeOnCCA
   * Shift the CC2420 Radio into transmit mode when the next clear channel
   * is detected.
   *
   * return SUCCESS if the transmit request has been accepted
   *************************************************************************/
  async command error_t CC2420Control.TxModeOnCCA() {
   call HPLChipcon.cmd(CC2420_STXONCCA);
   return SUCCESS;
  }

  /*************************************************************************
   * RxMode
   * Shift the CC2420 Radio into receive mode 
   *************************************************************************/
  async command error_t CC2420Control.RxMode() {
    call HPLChipcon.cmd(CC2420_SRXON);
    return SUCCESS;
  }

  /*************************************************************************
   * SetRFPower
   * power = 31 => full power    (0dbm)
   *          3 => lowest power  (-25dbm)
   * return SUCCESS if the radio power was successfully set
   *************************************************************************/
  command error_t CC2420Control.SetRFPower(uint8_t power) {
    gCurrentParameters[CP_TXCTRL] = (gCurrentParameters[CP_TXCTRL] & (~CC2420_TXCTRL_PAPWR_MASK)) | (power << CC2420_TXCTRL_PAPWR);
    call HPLChipcon.write(CC2420_TXCTRL,gCurrentParameters[CP_TXCTRL]);
    return SUCCESS;
  }

  /*************************************************************************
   * GetRFPower
   * return power seeting
   *************************************************************************/
  command uint8_t CC2420Control.GetRFPower() {
    return (gCurrentParameters[CP_TXCTRL] & CC2420_TXCTRL_PAPWR_MASK); //rfpower;
  }

  async command error_t CC2420Control.OscillatorOn() {
    uint16_t i;
    uint8_t status;

    i = 0;

    // uncomment to measure the startup time from 
    // high to low to high transitions
    // output "1" on the CCA pin
#ifdef CC2420_MEASURE_OSCILLATOR_STARTUP
      call HPLChipcon.write(CC2420_IOCFG1, 31);
      // output oscillator stable on CCA pin
      // error in CC2420 datasheet 1.2: SFDMUX and CCAMUX incorrectly labelled
      TOSH_uwait(50);
#endif

    call HPLChipcon.write(CC2420_IOCFG1, 24);

    // have an event/interrupt triggered when it starts up
    call CCA.startWait(TRUE);
    
    // start the oscillator
    status = call HPLChipcon.cmd(CC2420_SXOSCON);   //turn-on crystal

    return SUCCESS;
  }

  async command error_t CC2420Control.OscillatorOff() {
    call HPLChipcon.cmd(CC2420_SXOSCOFF);   //turn-off crystal
    return SUCCESS;
  }

  async command error_t CC2420Control.VREFOn(){
    call RadioVREF.set(); // turn-on
    // TODO: JP: measure the actual time for VREF to stabilize
    TOSH_uwait(600);  // CC2420 spec: 600us max turn on time
    return SUCCESS;
  }

  async command error_t CC2420Control.VREFOff(){
    call RadioVREF.clr();
    return SUCCESS;
  }

  async command error_t CC2420Control.enableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_AUTOACK);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.disableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_AUTOACK);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.enableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_ADRDECODE);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.disableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_ADRDECODE);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  command error_t CC2420Control.setShortAddress(uint16_t addr) {
    addr = toLSB16(addr);
    return call HPLChipconRAM.write(CC2420_RAM_SHORTADR, 2, (uint8_t*)&addr);
  }

  event error_t HPLChipconRAM.readDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
     return SUCCESS;
  }

  event error_t HPLChipconRAM.writeDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
     return SUCCESS;
  }

  async event void CCA.fired() {
    // reset the CCA pin back to the CCA function
    call HPLChipcon.write(CC2420_IOCFG1, 0);
    call CCA.disable();
    post PostOscillatorOn();
  }
}

