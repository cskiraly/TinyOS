/*
 * Copyright (c) 2010 Aarhus University
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
 * - Neither the name of Aarhus University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL AARHUS
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Morten Tranberg Hansen
 * @date   November 12 2010
 */

configuration MessageC {
  
  provides {
    interface SplitControl[radio_id_t id];
    
    // TODO: should be Send instead AMSend, and then the AM layer
    // should be implemented as a general layer on top of the
    // platforms MessageC.  This would mean that *RadioC components
    // should provide Send instead of AMSend which we leave to future
    // work (or the new TinyOS message_t abstraction).
    interface AMSend[radio_id_t id];
    interface Receive[radio_id_t id];
    interface Receive as Snoop[radio_id_t id];
    
    interface Packet[radio_id_t id];
    interface AMPacket[radio_id_t id];
    interface PacketAcknowledgements[radio_id_t id];
    //interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio[radio_id_t id];
    //interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli[radio_id_t id];
    interface LowPowerListening[radio_id_t id];
  }

} implementation {

  components 
    RF230RadioC as Radio0,
    RF212RadioC as Radio1,
    new AMIdDispatchP() as Dispatch0,
    new AMIdDispatchP() as Dispatch1;

  Dispatch0.SubSend -> Radio0;
  Dispatch0.SubReceive -> Radio0.Receive;
  Dispatch0.SubSnoop -> Radio0.Snoop;
  Dispatch0.AMPacket -> Radio0;

  Dispatch1.SubSend -> Radio1;
  Dispatch1.SubReceive -> Radio1.Receive;
  Dispatch1.SubSnoop -> Radio1.Snoop;
  Dispatch1.AMPacket -> Radio1;

  SplitControl[0] = Radio0;
  AMSend[0] = Dispatch0;
  Receive[0] = Dispatch0.Receive;
  Snoop[0] = Dispatch0.Snoop;
  Packet[0] = Radio0;
  AMPacket[0] = Radio0;
  PacketAcknowledgements[0] = Radio0;
  LowPowerListening[0] = Radio0;

  SplitControl[1] = Radio1;
  AMSend[1] = Dispatch1;
  Receive[1] = Dispatch1.Receive;
  Snoop[1] = Dispatch1.Snoop;
  Packet[1] = Radio1;
  AMPacket[1] = Radio1;
  PacketAcknowledgements[1] = Radio1;
  LowPowerListening[1] = Radio1;

}

