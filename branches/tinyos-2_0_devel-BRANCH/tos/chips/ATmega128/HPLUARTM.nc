/// $Id: HPLUARTM.nc,v 1.1.2.4 2005-05-18 23:28:13 idgay Exp $

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

#include <ATm128UART.h>

module HPLUARTM
{
  provides {
      interface HPLUART as UART0;
      interface HPLUART as UART1;
  }
}
implementation
{
  //=== UART Init Commands. ====================================
  async command error_t UART0.init() {
      ATm128UARTMode_t    mode;
      ATm128UARTStatus_t  stts;
      ATm128UARTControl_t ctrl;

      ctrl.bits = (struct ATm128_UCSRB_t) {rxcie:1, txcie:1, rxen:1, txen:1};
      stts.bits = (struct ATm128_UCSRA_t) {u2x:1};
      mode.bits = (struct ATm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

      UBRR0L = ATM128_57600_BAUD_7MHZ_2X;
      UBRR0H = ATM128_57600_BAUD_7MHZ_2X >> 8;
      UCSR0A = stts.flat;
      UCSR0C = mode.flat;
      UCSR0B = ctrl.flat;

      return SUCCESS;
  }
  async command error_t UART1.init() {
      ATm128UARTMode_t    mode;
      ATm128UARTStatus_t  stts;
      ATm128UARTControl_t ctrl;

      ctrl.bits = (struct ATm128_UCSRB_t) {rxcie:1, txcie:1, rxen:1, txen:1};
      stts.bits = (struct ATm128_UCSRA_t) {u2x:1};
      mode.bits = (struct ATm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

      UBRR1L = ATM128_57600_BAUD_7MHZ_2X;
      UBRR1H = ATM128_57600_BAUD_7MHZ_2X >> 8;
      UCSR1A = stts.flat;
      UCSR1C = mode.flat;
      UCSR1B = ctrl.flat;

      return SUCCESS;
  }

  //=== UART Stop Commands. ====================================
  async command error_t UART0.stop() {
      UCSR0A = 0;
      UCSR0B = 0;
      UCSR0C = 0;
      return SUCCESS;
  }
  async command error_t UART1.stop() {
      UCSR0A = 0;
      UCSR0B = 0;
      UCSR0C = 0;
      return SUCCESS;
  }

  //=== UART Put Commands. ====================================
  async command error_t UART0.put(uint8_t data) {
      atomic{
	  UDR0 = data; 
	  SET_BIT(UCSR0A, TXC);
      }
      return SUCCESS;
  }
  async command error_t UART1.put(uint8_t data) {
      atomic{
	  UDR1 = data; 
	  SET_BIT(UCSR1A, TXC);
      }
      return SUCCESS;
  }
  
  //=== UART Get Events. ======================================
  default async event error_t UART0.get(uint8_t data) { return SUCCESS; }
  AVR_ATOMIC_HANDLER(SIG_UART0_RECV) {
      if (READ_BIT(UCSR0A, RXC))
	  signal UART0.get(UDR0);
  }
  default async event error_t UART1.get(uint8_t data) { return SUCCESS; }
  AVR_ATOMIC_HANDLER(SIG_UART1_RECV) {
      if (READ_BIT(UCSR1A, RXC))
	  signal UART1.get(UDR1);
  }

  //=== UART Put Done Events. =================================
  default async event error_t UART0.putDone() { return SUCCESS; }
  AVR_NONATOMIC_HANDLER(SIG_UART0_TRANS) {
      signal UART0.putDone();
  }
  default async event error_t UART1.putDone() { return SUCCESS; }
  AVR_NONATOMIC_HANDLER(SIG_UART1_TRANS) {
      signal UART1.putDone();
  }

}
