/* $Id: CC1000RssiM.nc,v 1.1.2.1 2005-05-24 21:26:01 idgay Exp $
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
     RSSI fun. It's used for lots of things, and a request to read it
     for one purpose may have to be discarded if conditions change. For
     example, if we've initiated a noise-floor measure, but start 
     receiving a packet, we have to:
     - cancel the noise-floor measure (we don't know if the value will
       reflect the received packet or the previous idle state)
     - start an RSSI measurement so that we can report signal strength
       to the application

     This module hides the complexities of cancellation from the rest of
     the stack.
*/

#define CC1000RSSI "cc1000.rssi"
module CC1000RssiM
{
  provides {
    interface AcquireDataNow as Rssi[uint8_t reason];
    async command void cancel();
  }
  uses interface AcquireDataNow as ActualRssi;
}
implementation
{
  enum {
    IDLE = unique(CC1000RSSI),
    CANCELLED = unique(CC1000RSSI)
  };

  /* All commands are called within atomic sections */
  uint8_t currentOp = IDLE;
  uint8_t nextOp;

  async command void cancel() {
    if (currentOp != IDLE)
      currentOp = CANCELLED;
  }

  async command error_t Rssi.getData[uint8_t reason]() {
    if (currentOp == IDLE)
      {
	currentOp = reason;
	call ActualRssi.getData();
      }
    else // We should only come here with currentOp = CANCELLED
      nextOp = reason;
  }

  void startNextOp() {
    if (nextOp != IDLE)
      {
	currentOp = nextOp;
	nextOp = IDLE;
	call ActualRssi.getData();
      }
    else
      currentOp = IDLE;
  }

  async event void ActualRssi.dataReady(uint16_t data) {
    atomic
      {
	uint8_t op = currentOp;

	/* The code assumes that RSSI measurements are 10-bits 
	   (legacy effect) */
	data >>= 6;
	startNextOp();

	signal Rssi.dataReady[op](data);
      }
  }

  event void ActualRssi.error(uint16_t info) {
    uint8_t op;

    atomic
      {
	op = currentOp;
	startNextOp();
      }
    signal Rssi.error[op](info);
  }

  default event void Rssi.error[uint8_t reason](uint16_t info) { }
  default async event void Rssi.dataReady[uint8_t reason](uint16_t data) { }
}
