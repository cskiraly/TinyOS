/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:05:14 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_platform_H
#define __TKN154_platform_H

/**************************************************** 
 * The following constants define guard times on Tmote Sky / TelosB. 
 * All values are in symbol time (1 symbol = 16 us)
 */

enum {
  // guard time to give up the token before actual end of CAP/CFP
  IEEE154_RADIO_GUARD_TIME = 1000,

  // the expected time for a RadioTx.prepare() operation to execute (return)
  IEEE154_RADIO_TX_PREPARE_DELAY = 220,

  // the *guaranteed maximum* time between calling a RadioTx.transmit() and the
  // first PPDU bit being put onto the channel, assuming that RadioTx.transmit() 
  // is called inside an atomic block
  IEEE154_RADIO_TX_SEND_DELAY = 100,

  // the expected time for a RadioRx.prepare() operation to execute (return)
  IEEE154_RADIO_RX_PREPARE_DELAY = 300,

  // the *guaranteed maximum* time between calling a RadioTx.transmit() and the
  // first PPDU bit being put onto the channel, assuming that RadioTx.transmit() 
  // is called inside an atomic block
  IEEE154_RADIO_RX_DELAY = 100,

  // defines at what time the MAC payload for a beacon frame is assembled prior
  // to the next scheduled beacon transmission time; must be smaller than both
  // the beacon interval and IEEE154_RADIO_TX_PREPARE_DELAY
  BEACON_PAYLOAD_UPDATE_INTERVAL = 2500, 
};

typedef uint32_t ieee154_reftime_t;

#endif
