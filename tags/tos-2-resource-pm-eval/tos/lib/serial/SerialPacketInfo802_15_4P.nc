//$Id: SerialPacketInfo802_15_4P.nc,v 1.1.2.2 2006-02-14 17:01:44 idgay Exp $

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
 * Implementation of the metdata necessary for a dispatcher to
 * communicate 802.15.4 message_t packets over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "802_15_4.h"
module SerialPacketInfo802_15_4P {
  provides interface SerialPacketInfo as Info;
}
implementation {
  async command uint8_t Info.offset() {
    return sizeof(TOSRadioHeader) - sizeof(TOS802Header);
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(TOS802Header) + sizeof(TOS802Footer);
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - (sizeof(TOS802Header) + sizeof(TOS802Footer));
  }
}
