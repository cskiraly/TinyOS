//$Id: SerialPacketInfoActiveMessageP.nc,v 1.1.2.6 2005-10-31 19:53:52 scipio Exp $

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
 * Implementation of the metadata neccessary for a dispatcher to
 * communicate with basic active messages packets over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

includes Serial;

module SerialPacketInfoActiveMessageP {
  provides interface SerialPacketInfo as Info;
  provides interface Packet;
  provides interface AMPacket;
}
implementation {

  async command uint8_t Info.offset() {
    return (uint8_t)(sizeof(TOSRadioHeader) - sizeof(SerialAMHeader));
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(SerialAMHeader);
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - sizeof(SerialAMHeader);
  }

  command void Packet.clear(message_t* msg) {
    return;
  }

  SerialAMHeader* getHeader(message_t* msg) {
    return (SerialAMHeader*)(msg->data - sizeof(SerialAMHeader));
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

