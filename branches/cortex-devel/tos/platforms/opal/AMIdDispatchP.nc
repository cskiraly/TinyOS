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

generic module AMIdDispatchP() {

  provides {
    interface AMSend as Send;
    interface Receive;
    interface Receive as Snoop;
  }

  uses {
    interface AMSend as SubSend[am_id_t id];
    interface Receive as SubReceive[am_id_t id];
    interface Receive as SubSnoop[am_id_t id];
    interface AMPacket;
  }

} implementation {

  /***************** Send ****************/

  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return call SubSend.send[call AMPacket.type(msg)](addr, msg, len);
  }

  command error_t Send.cancel(message_t* msg) {
    return call SubSend.cancel[call AMPacket.type(msg)](msg);
  }

  event void SubSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    signal Send.sendDone(msg, error);
  }

  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength[0]();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload[call AMPacket.type(msg)](msg, len);
  }

  /***************** Receive ****************/

  event message_t* SubReceive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    call AMPacket.setType(msg, id);
    return signal Receive.receive(msg, payload, len);
  }

  /***************** Snoop ****************/

  event message_t* SubSnoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    call AMPacket.setType(msg, id);
    return signal Snoop.receive(msg, payload, len);
  }

  /***************** Defaults ****************/

  default event void Send.sendDone(message_t* msg, error_t error) {}

  default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event message_t* Snoop.receive(message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

}
