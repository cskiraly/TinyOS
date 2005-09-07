// $Id: HplInterruptC.nc,v 1.1.2.2 2005-09-07 16:47:51 scipio Exp $

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

#include <atm128hardware.h>

configuration HplInterruptC
{
  // provides all the ports as raw ports
  provides {
    interface HplInterrupt as Int0;
    interface HplInterrupt as Int1;
    interface HplInterrupt as Int2;
    interface HplInterrupt as Int3;
    interface HplInterrupt as Int4;
    interface HplInterrupt as Int5;
    interface HplInterrupt as Int6;
    interface HplInterrupt as Int7;
  }
}
implementation
{
#define IRQ_PORT_D_PIN(bit) (uint8_t)&EICRA, ISC##bit##0, ISC##bit##1, bit
#define IRQ_PORT_E_PIN(bit) (uint8_t)&EICRB, ISC##bit##0, ISC##bit##1, bit

  components 
    HplInterruptSigP as IrqVector, LedsC,
    new HplInterruptPinP(IRQ_PORT_D_PIN(0)) as IntPin0,
    new HplInterruptPinP(IRQ_PORT_D_PIN(1)) as IntPin1,
    new HplInterruptPinP(IRQ_PORT_D_PIN(2)) as IntPin2,
    new HplInterruptPinP(IRQ_PORT_D_PIN(3)) as IntPin3,
    new HplInterruptPinP(IRQ_PORT_E_PIN(4)) as IntPin4,
    new HplInterruptPinP(IRQ_PORT_E_PIN(5)) as IntPin5,
    new HplInterruptPinP(IRQ_PORT_E_PIN(6)) as IntPin6,
    new HplInterruptPinP(IRQ_PORT_E_PIN(7)) as IntPin7;
  
  Int0 = IntPin0;
  Int1 = IntPin1;
  Int2 = IntPin2;
  Int3 = IntPin3;
  Int4 = IntPin4;
  Int5 = IntPin5;
  Int6 = IntPin6;
  Int7 = IntPin7;

  IntPin0.IrqSignal -> IrqVector.IntSig0;
  IntPin1.IrqSignal -> IrqVector.IntSig1;
  IntPin2.IrqSignal -> IrqVector.IntSig2;
  IntPin3.IrqSignal -> IrqVector.IntSig3;
  IntPin4.IrqSignal -> IrqVector.IntSig4;
  IntPin5.IrqSignal -> IrqVector.IntSig5;
  IntPin6.IrqSignal -> IrqVector.IntSig6;
  IntPin7.IrqSignal -> IrqVector.IntSig7;

  IrqVector.Leds -> LedsC;
}

