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

generic configuration CC2420SpiC() {

  provides interface Init;
  provides interface Resource;

  // commands
  provides interface CC2420Strobe as SFLUSHRX;
  provides interface CC2420Strobe as SFLUSHTX;
  provides interface CC2420Strobe as SNOP;
  provides interface CC2420Strobe as SRXON;
  provides interface CC2420Strobe as SRFOFF;
  provides interface CC2420Strobe as STXON;
  provides interface CC2420Strobe as STXONCCA;
  provides interface CC2420Strobe as SXOSCON;
  provides interface CC2420Strobe as SXOSCOFF;

  // registers
  provides interface CC2420Register as FSCTRL;
  provides interface CC2420Register as IOCFG0;
  provides interface CC2420Register as IOCFG1;
  provides interface CC2420Register as MDMCTRL0;
  provides interface CC2420Register as MDMCTRL1;
  provides interface CC2420Register as TXCTRL;

  // ram
  provides interface CC2420Ram as IEEEADR;
  provides interface CC2420Ram as PANID;
  provides interface CC2420Ram as SHORTADR;
  provides interface CC2420Ram as TXFIFO_RAM;

  // fifos
  provides interface CC2420Fifo as RXFIFO;
  provides interface CC2420Fifo as TXFIFO;

}

implementation {

  components HplCC2420PinsC as Pins;
  components new HplCC2420SpiC();
  components CC2420SpiP as Spi;
  
  Init = HplCC2420SpiC;
  Resource = HplCC2420SpiC;

  // commands
  SFLUSHRX = Spi.Strobe[ CC2420_SFLUSHRX ];
  SFLUSHTX = Spi.Strobe[ CC2420_SFLUSHTX ];
  SNOP = Spi.Strobe[ CC2420_SNOP ];
  SRXON = Spi.Strobe[ CC2420_SRXON ];
  SRFOFF = Spi.Strobe[ CC2420_SRFOFF ];
  STXON = Spi.Strobe[ CC2420_STXON ];
  STXONCCA = Spi.Strobe[ CC2420_STXONCCA ];
  SXOSCON = Spi.Strobe[ CC2420_SXOSCON ];
  SXOSCOFF = Spi.Strobe[ CC2420_SXOSCOFF ];

  // registers
  FSCTRL = Spi.Reg[ CC2420_FSCTRL ];
  IOCFG0 = Spi.Reg[ CC2420_IOCFG0 ];
  IOCFG1 = Spi.Reg[ CC2420_IOCFG1 ];
  MDMCTRL0 = Spi.Reg[ CC2420_MDMCTRL0 ];
  MDMCTRL1 = Spi.Reg[ CC2420_MDMCTRL1 ];
  TXCTRL = Spi.Reg[ CC2420_TXCTRL ];

  // ram
  IEEEADR = Spi.Ram[ CC2420_RAM_IEEEADR ];
  PANID = Spi.Ram[ CC2420_RAM_PANID ];
  SHORTADR = Spi.Ram[ CC2420_RAM_SHORTADR ];
  TXFIFO_RAM = Spi.Ram[ CC2420_RAM_TXFIFO ];

  // fifos
  RXFIFO = Spi.Fifo[ CC2420_RXFIFO ];
  TXFIFO = Spi.Fifo[ CC2420_TXFIFO ];

}

