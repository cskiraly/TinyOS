/// $Id: HPLSPIM.nc,v 1.1.2.1 2005-06-04 23:56:53 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#include <ATm128SPI.h>

module HPLSPIM
{
    provides interface Init;
    provides interface HPLSPI as SPI;

    uses {
	interface GeneralIO as Ss;   // Slave set line
	interface GeneralIO as Sck;  // SPI clock line
	interface GeneralIO as Mosi; // Master out, slave in
	interface GeneralIO as Miso; // Master in, slave out
    }
}
implementation
{
  //=== SPI Bus initialization. =========================================
  command error_t Init.init() {
      // Default to slave rx pin settings
      call SPI.slaveInit();
  }

  //=== Read/Write the data register. ===================================
  async command uint8_t SPI.read()        { return SPDR; }
  async command void SPI.write(uint8_t d) { SPDR = d; }
    
  default async event void SPI.dataReady(uint8_t d) {}
  AVR_NONATOMIC_HANDLER(SIG_SPI) {
      signal SPI.dataReady(call SPI.read());
  }

  //=== Read the control registers. =====================================
  async command ATm128SPIControl_t SPI.getControl() {
      return *(ATm128SPIControl_t*)&SPCR;    
  }

  async command ATm128SPIStatus_t SPI.getStatus() {
      return *(ATm128SPIStatus_t*)&SPSR; 
  }

  //=== Write the control registers. ====================================
  async command void SPI.setControl(ATm128SPIControl_t ctrl) {
      SPCR = ctrl.flat; 
  }
  
  async command void SPI.setStatus(ATm128SPIStatus_t stts) {
      SPSR = stts.flat; 
  }

  
  //=== SPI Bus utility rouotines. ====================================
  async command bool SPI.isBusy() {
      return !(call SPI.getStatus()).bits.spif;
  }

#if 0
#define CONTROL_BIT_SERVICE(name, bit, type)             \
  async command ##type SPI.get##name () {                \
      return (call SPI.getControl()).bits.##bit##;       \
  }                                                      \
  async command error_t SPI.set##name (##type v) {       \
      ATm128SPIControl_t ctrl = call SPI.getControl();   \
      ctrl.bits.##bit = v;                               \
      call SPI.setControl(ctrl);                         \
      return SUCCESS;                                    \
  }

  CONTROL_BIT_SERVICE(Enable, spe, bool);
  CONTROL_BIT_SERVICE(Interrupt, spie, bool);
  CONTROL_BIT_SERVICE(Speed, spr, uint8_t);
#else

  async command bool SPI.getEnable () {                
      return (call SPI.getControl()).bits.spe;       
  }                                                      
  async command error_t SPI.setEnable (bool v) {       
      ATm128SPIControl_t ctrl = call SPI.getControl();   
      ctrl.bits.spe = v;                               
      call SPI.setControl(ctrl);                         
      return SUCCESS;                                    
  }

  async command bool SPI.getInterrupt () {                
      return (call SPI.getControl()).bits.spie;       
  }                                                      
  async command error_t SPI.setInterrupt (bool v) {       
      ATm128SPIControl_t ctrl = call SPI.getControl();   
      ctrl.bits.spie = v;                               
      call SPI.setControl(ctrl);                         
      return SUCCESS;                                    
  }

  async command uint8_t SPI.getSpeed () {                
      return (call SPI.getControl()).bits.spr;       
  }                                                      
  async command error_t SPI.setSpeed (uint8_t v) {       
      ATm128SPIControl_t ctrl = call SPI.getControl();   
      ctrl.bits.spr = v;                               
      call SPI.setControl(ctrl);                         
      return SUCCESS;                                    
  }

#endif 
  /**
   * Puts the bus to sleep.
   */
  async command error_t SPI.disable() {
/*
      call SPI.setStatus(0);
      call SPI.setControl(0);
*/
      CLR_BIT(SPCR, SPIE);
      call Ss.makeOutput();
      call Ss.set();     // Sleep bus
      //call Ss.clr();     // Allow slave transfers
      return SUCCESS;
  }
  
  //=== Slave initialization and control. ==============================

  async command error_t SPI.slaveInit() {  
      ATm128SPIControl_t ctrl;
      ATm128SPIStatus_t  stts;

      stts.bits = (ATm128SPIStatus_s) { spi2x : 1 };
      ctrl.bits = (ATm128SPIControl_s) {
	  spr  : ATM128_SPI_CLK_DIVIDE_4,
	  spie : 1,                       //!< Enable SPI Interrupt
	  spe  : 1,                       //!< Enable SPI 
      };

      call Ss.makeInput();     //!< Default for slave mode
      call Sck.makeInput();    //!< Default for slave mode
      call Mosi.makeInput();   //!< Default for slave mode

      call Miso.makeInput();   //!< user defined -- default to rx

      call SPI.setStatus(stts);
      call SPI.setControl(ctrl);
      return SUCCESS;
  }

  async command error_t SPI.slaveTx() {
      call Miso.makeOutput(); //!< Make slave output
      return SUCCESS;
  }
  
  async command error_t SPI.slaveRx() {
      call Miso.makeInput();   //!< Make slave input
      return SUCCESS;
  }

  //=== Master initialization and control. ==============================

  async command error_t SPI.masterInit() {
      ATm128SPIControl_t ctrl;
      ATm128SPIStatus_t  stts;

      stts.bits = (ATm128SPIStatus_s) { spi2x : 1 };
      ctrl.bits = (ATm128SPIControl_s) {
	  spr  : ATM128_SPI_CLK_DIVIDE_4,
	  mstr : 1,                       //<! Master mode 
	  spie : 1,                       //!< Enable SPI Interrupt
	  spe  : 1,                       //!< Enable SPI
      };

      call Miso.makeInput();    //!< Default for master mode

      call Mosi.makeOutput();   //!< user defined
      call Sck.makeOutput();    //!< user defined
      call Ss.makeOutput();     //!< user defined

      call SPI.setStatus(stts);
      call SPI.setControl(ctrl);
      return SUCCESS;
  }

  async command error_t SPI.masterTx() {
      call Mosi.makeOutput(); //!< Make master output
      return SUCCESS;
  }

  async command error_t SPI.masterRx() {
      call Mosi.makeInput(); //!< Make master input
      return SUCCESS;
  }

  async command error_t SPI.masterStart() {
      call Ss.clr();         //!< Start bus transfer
      return SUCCESS;
  }

  async command error_t SPI.masterStop() {
      call Ss.set();         //!< Stop bus transfer
      return SUCCESS;
  }

}
