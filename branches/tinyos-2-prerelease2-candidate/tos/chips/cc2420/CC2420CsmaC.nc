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

includes CC2420;
includes IEEE802154;

configuration CC2420CsmaC {

  provides interface Init;
  provides interface SplitControl;

  provides interface Send;
  provides interface Receive;
  provides interface PacketAcknowledgements as Acks;

}

implementation {

  components CC2420CsmaP as CsmaP;

  Init = CsmaP;
  Init = RandomC;
  SplitControl = CsmaP;
  Send = CsmaP;
  Acks = CsmaP;

  components CC2420ControlC;
  Init = CC2420ControlC;
  CsmaP.Resource -> CC2420ControlC;
  CsmaP.CC2420Config -> CC2420ControlC;

  components CC2420TransmitC;
  Init = CC2420TransmitC;
  CsmaP.SubControl -> CC2420TransmitC;
  CsmaP.CC2420Transmit -> CC2420TransmitC;
  CsmaP.CSMABackoff -> CC2420TransmitC;

  components CC2420ReceiveC;
  Init = CC2420ReceiveC;
  Receive = CC2420ReceiveC;
  CsmaP.SubControl -> CC2420ReceiveC;

  components RandomC;
  CsmaP.Random -> RandomC;

  components NoLedsC as Leds;
  CsmaP.Leds -> Leds;

}
