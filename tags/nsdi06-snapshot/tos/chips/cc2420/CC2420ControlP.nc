/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
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
 * Control operations for the ChipCon CC2420 radio. This component
 * is platform independent.
 *
 * <pre>
 *  $Id: CC2420ControlP.nc,v 1.1.2.2 2005-09-22 00:45:01 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Alan Broad, Crossbow
 * @author Joe Polastre
 */

module CC2420ControlP {

  provides {
    interface Init;
    interface SplitControl;
    interface CC2420Control;
  }
  uses {
    interface Init as HPLChipconInit;
    interface StdControl as HPLChipconControl;
    interface CC2420Ram as Ram;
    interface Interrupt as CCA;

    interface CC2420RWRegister as MAIN;
    interface CC2420RWRegister as MDMCTRL0;
    interface CC2420RWRegister as MDMCTRL1;
    interface CC2420RWRegister as RSSI;
    interface CC2420RWRegister as SYNCWORD;
    interface CC2420RWRegister as TXCTRL;
    interface CC2420RWRegister as RXCTRL0;
    interface CC2420RWRegister as RXCTRL1;
    interface CC2420RWRegister as FSCTRL;
    interface CC2420RWRegister as SECCTRL0;
    interface CC2420RWRegister as SECCTRL1;
    interface CC2420RWRegister as IOCFG0;
    interface CC2420RWRegister as IOCFG1;

    interface CC2420StrobeRegister as SFLUSHTX;
    interface CC2420StrobeRegister as SFLUSHRX;
    interface CC2420StrobeRegister as SXOSCOFF;
    interface CC2420StrobeRegister as SXOSCON;
    interface CC2420StrobeRegister as SRXON;
    interface CC2420StrobeRegister as STXON;
    interface CC2420StrobeRegister as STXONCCA;
    
    interface GeneralIO as CC_RSTN;
    interface GeneralIO as CC_VREN;
    
    interface Leds;
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
	      
    call MAIN.write(gCurrentParameters[CP_MAIN]);   		    
    call MDMCTRL0.write(gCurrentParameters[CP_MDMCTRL0]);
    call MDMCTRL0.read(&data);
    if (data != gCurrentParameters[CP_MDMCTRL0]) return FALSE;
    
    call MDMCTRL1.write(gCurrentParameters[CP_MDMCTRL1]);
    call RSSI.write(gCurrentParameters[CP_RSSI]);
    call SYNCWORD.write(gCurrentParameters[CP_SYNCWORD]);
    call TXCTRL.write(gCurrentParameters[CP_TXCTRL]);
    call RXCTRL0.write(gCurrentParameters[CP_RXCTRL0]);
    call RXCTRL1.write(gCurrentParameters[CP_RXCTRL1]);
    call FSCTRL.write(gCurrentParameters[CP_FSCTRL]);

    call SECCTRL0.write(gCurrentParameters[CP_SECCTRL0]);
    call SECCTRL1.write(gCurrentParameters[CP_SECCTRL1]);
    call IOCFG0.write(gCurrentParameters[CP_IOCFG0]);
    call IOCFG1.write(gCurrentParameters[CP_IOCFG1]);

    call SFLUSHTX.cmd();    //flush Tx fifo
    call SFLUSHRX.cmd();
 
    return TRUE;
  
  }

  task void taskStopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  task void PostOscillatorOn() {
    //set freq, load regs
    SetRegs();
    call CC2420Control.setShortAddress(TOS_LOCAL_ADDRESS);
    call CC2420Control.TuneManual(((gCurrentParameters[CP_FSCTRL] << CC2420_FSCTRL_FREQ) & 0x1FF) + 2048);
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

    call SXOSCOFF.cmd(); 
    ok = call CCA.disable();
    ok = ecombine(call HPLChipconControl.stop(), ok);

    call CC_RSTN.clr();
    ok = ecombine(call CC2420Control.VREFOff(), ok);
    call CC_RSTN.set();

    if (ok == SUCCESS)
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
    call CC_RSTN.clr();
    uwait(1);
    call CC_RSTN.set();
    uwait(1);
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
    status = call FSCTRL.write(gCurrentParameters[CP_FSCTRL]);
    // if the oscillator is started, recalibrate for the new frequency
    // if the oscillator is NOT on, we should not transition to RX mode
    if (status & CC2420_XOSC16M_STABLE) {
      call SRXON.cmd();
    }
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
    status = call FSCTRL.write(gCurrentParameters[CP_FSCTRL]);
    // if the oscillator is started, recalibrate for the new frequency
    // if the oscillator is NOT on, we should not transition to RX mode
    if (status & CC2420_XOSC16M_STABLE) {
      call SRXON.cmd();
    }
    return SUCCESS;
  }

  /*************************************************************************
   * Get the current frequency of the radio
   */
  command uint16_t CC2420Control.GetFrequency() {
    return ((gCurrentParameters[CP_FSCTRL] & (0x1FF << CC2420_FSCTRL_FREQ))+2048);
  }

  /*************************************************************************
   * Get the current channel of the radio
   */
  command uint8_t CC2420Control.GetPreset() {
    uint16_t _freq = (gCurrentParameters[CP_FSCTRL] & (0x1FF << CC2420_FSCTRL_FREQ));
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
    call STXON.cmd();
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
   call STXONCCA.cmd();
   return SUCCESS;
  }

  /*************************************************************************
   * RxMode
   * Shift the CC2420 Radio into receive mode 
   *************************************************************************/
  async command error_t CC2420Control.RxMode() {
    call SRXON.cmd();
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
    call TXCTRL.write(gCurrentParameters[CP_TXCTRL]);
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
      call IOCFG1.write(31);
      // output oscillator stable on CCA pin
      // error in CC2420 datasheet 1.2: SFDMUX and CCAMUX incorrectly labelled
      uwait(50);
#endif

    call IOCFG1.write(24);

    // have an event/interrupt triggered when it starts up
    call CCA.startWait(TRUE);
    
    // start the oscillator
    status = call SXOSCON.cmd();   //turn-on crystal

    return SUCCESS;
  }

  async command error_t CC2420Control.OscillatorOff() {
    call SXOSCOFF.cmd();   //turn-off crystal
    return SUCCESS;
  }

  async command error_t CC2420Control.VREFOn(){
    call CC_VREN.set();                    //turn-on  
    // TODO: JP: measure the actual time for VREF to stabilize
    uwait(600);  // CC2420 spec: 600us max turn on time
    return SUCCESS;
  }

  async command error_t CC2420Control.VREFOff(){
    call CC_VREN.clr();                    //turn-off  
    return SUCCESS;
  }

  async command error_t CC2420Control.enableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_AUTOACK);
    return call MDMCTRL0.write(gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.disableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_AUTOACK);
    return call MDMCTRL0.write(gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.enableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_ADRDECODE);
    return call MDMCTRL0.write(gCurrentParameters[CP_MDMCTRL0]);
  }

  async command error_t CC2420Control.disableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_ADRDECODE);
    return call MDMCTRL0.write(gCurrentParameters[CP_MDMCTRL0]);
  }

  command error_t CC2420Control.setShortAddress(uint16_t addr) {
    nx_uint16_t realAddr;
    realAddr = addr;
    return call Ram.write(CC2420_RAM_SHORTADR, (uint8_t*)&realAddr, 2);
  }

  async event void Ram.readDone(uint16_t addr, uint8_t* buf, uint8_t length, error_t err) {}

  async event void Ram.writeDone(uint16_t addr, uint8_t* buf, uint8_t length, error_t err) {}

  async event void CCA.fired() {
    uint8_t oldState;
    // reset the CCA pin back to the CCA function
    call IOCFG1.write(0);
    atomic oldState = state;
    if (oldState == START_STATE) {
      post PostOscillatorOn();
    }
    return;
  }
	
}
