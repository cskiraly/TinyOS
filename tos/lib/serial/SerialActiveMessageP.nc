//$Id: SerialActiveMessageP.nc,v 1.1.2.1 2005-08-12 00:35:41 scipio Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Sending active messages over the serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

includes Serial;
generic module SerialActiveMessageP () {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface AMPacket;
    interface Packet;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
  }
}
implementation {

  SerialAMHeader* getHeader(message_t* msg) {
    return (SerialAMHeader*)(msg->data - sizeof(SerialAMHeader));
  }
  
  command error_t AMSend.send[am_id_t id](am_addr_t dest,
					  message_t* msg,
					  uint8_t len) {
    SerialAMHeader* header = getHeader(msg);
    header->addr = dest;
    header->type = id;
    header->length = len;
    header->group = TOS_AM_GROUP;
    return call SubSend.send(msg, len);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
  }

  command void Packet.clear(message_t* msg) {
    return;
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    SerialAMHeader* header = getHeader(msg);    
    return header->length;
  }

  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }


  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    if (len != NULL) { 
      *len = call Packet.payloadLength(msg);
    }
    return msg->data;
  }

  command am_addr_t AMPacket.address() {
    return 0;
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    SerialAMHeader* header = getHeader(amsg);
    return header->addr;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return TRUE;
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    SerialAMHeader* header = getHeader(amsg);
    return header->type;
  }
}
