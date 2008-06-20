/// $Id: HplUartC.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $

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

#include <Atm128Uart.h>

module HplUartC
{
  provides {
    interface Init as Uart0Init;
    interface Init as Uart1Init;
    interface SerialByteComm as Uart0;
    interface SerialByteComm as Uart1;
  }
}
implementation
{
  //=== Uart Init Commands. ====================================
  command error_t Uart0Init.init() {
    Atm128UartMode_t    mode;
    Atm128UartStatus_t  stts;
    Atm128UartControl_t ctrl;

    ctrl.bits = (struct Atm128_UCSRB_t) {rxcie:1, txcie:1, rxen:1, txen:1};
    stts.bits = (struct Atm128_UCSRA_t) {u2x:1};
    mode.bits = (struct Atm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

    UBRR0L = ATM128_57600_BAUD_7MHZ_2X;
    UBRR0H = ATM128_57600_BAUD_7MHZ_2X >> 8;
    UCSR0A = stts.flat;
    UCSR0C = mode.flat;
    UCSR0B = ctrl.flat;

    return SUCCESS;
  }

  command error_t Uart1Init.init() {
    Atm128UartMode_t    mode;
    Atm128UartStatus_t  stts;
    Atm128UartControl_t ctrl;

    ctrl.bits = (struct Atm128_UCSRB_t) {rxcie:1, txcie:1, rxen:1, txen:1};
    stts.bits = (struct Atm128_UCSRA_t) {u2x:1};
    mode.bits = (struct Atm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

    UBRR1L = ATM128_57600_BAUD_7MHZ_2X;
    UBRR1H = ATM128_57600_BAUD_7MHZ_2X >> 8;
    UCSR1A = stts.flat;
    UCSR1C = mode.flat;
    UCSR1B = ctrl.flat;

    return SUCCESS;
  }

  /*   //=== Uart Stop Commands. ==================================== */
  /*   async command error_t Uart0.stop() { */
  /*       UCSR0A = 0; */
  /*       UCSR0B = 0; */
  /*       UCSR0C = 0; */
  /*       return SUCCESS; */
  /*   } */
  /*   async command error_t Uart1.stop() { */
  /*       UCSR0A = 0; */
  /*       UCSR0B = 0; */
  /*       UCSR0C = 0; */
  /*       return SUCCESS; */
  /*   } */

  //=== Uart Put Commands. ====================================
  async command error_t Uart0.put(uint8_t data) {
    atomic{
      UDR0 = data; 
      SET_BIT(UCSR0A, TXC);
    }
    return SUCCESS;
  }
  async command error_t Uart1.put(uint8_t data) {
    atomic{
      UDR1 = data; 
      SET_BIT(UCSR1A, TXC);
    }
    return SUCCESS;
  }
  
  //=== Uart Get Events. ======================================
  default async event void Uart0.get(uint8_t data) { return; }
  AVR_ATOMIC_HANDLER(SIG_UART0_RECV) {
    if (READ_BIT(UCSR0A, RXC))
      signal Uart0.get(UDR0);
  }
  default async event void Uart1.get(uint8_t data) { return; }
  AVR_ATOMIC_HANDLER(SIG_UART1_RECV) {
    if (READ_BIT(UCSR1A, RXC))
      signal Uart1.get(UDR1);
  }

  //=== Uart Put Done Events. =================================
  default async event void Uart0.putDone() { return; }
  AVR_NONATOMIC_HANDLER(SIG_UART0_TRANS) {
    signal Uart0.putDone();
  }
  default async event void Uart1.putDone() { return; }
  AVR_NONATOMIC_HANDLER(SIG_UART1_TRANS) {
    signal Uart1.putDone();
  }

}