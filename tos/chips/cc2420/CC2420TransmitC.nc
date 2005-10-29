/**
 * Copyright (c) 2005 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 *
 * $ Revision: $
 * $ Date: $
 */

configuration CC2420TransmitC {

  provides interface Init;
  provides interface AsyncControl;
  provides interface CC2420Transmit;
  provides interface CSMABackoff;
  provides interface RadioTimeStamping;

}

implementation {

  components CC2420TransmitP;
  components AlarmMultiplexC as Alarm;
  components new CC2420SpiC() as Spi;

  components HplCC2420InterruptsC as Interrupts;
  components HplCC2420PinsC as Pins;

  components LedsC as Leds;
  CC2420TransmitP.Leds -> Leds;

  Init = Alarm;
  Init = CC2420TransmitP;
  AsyncControl = CC2420TransmitP;
  CC2420Transmit = CC2420TransmitP;
  CSMABackoff = CC2420TransmitP;
  RadioTimeStamping = CC2420TransmitP;

  CC2420TransmitP.BackoffTimer -> Alarm;

  CC2420TransmitP.CCA -> Pins.CCA;
  CC2420TransmitP.CSN -> Pins.CSN;
  CC2420TransmitP.SFD -> Pins.SFD;
  CC2420TransmitP.CaptureSFD -> Interrupts.CaptureSFD;

  CC2420TransmitP.SpiResource -> Spi;
  CC2420TransmitP.SNOP -> Spi.SNOP;
  CC2420TransmitP.STXON -> Spi.STXON;
  CC2420TransmitP.STXONCCA -> Spi.STXONCCA;
  CC2420TransmitP.TXFIFO -> Spi.TXFIFO;
  CC2420TransmitP.TXFIFO_RAM -> Spi.TXFIFO_RAM;

  components CC2420ReceiveC;
  CC2420TransmitP.CC2420Receive -> CC2420ReceiveC;

}
