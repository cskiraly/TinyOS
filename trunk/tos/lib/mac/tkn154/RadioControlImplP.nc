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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"
#include "TKN154_DEBUG.h"
module RadioControlImplP 
{
  provides
  {
    interface RadioRx as MacRx[uint8_t client];
    interface RadioTx as MacTx[uint8_t client];
    interface RadioOff as MacRadioOff[uint8_t client];
  } uses {
    interface ArbiterInfo;
    interface RadioRx as PhyRx;
    interface RadioTx as PhyTx;
    interface RadioOff as PhyRadioOff;
    interface Get<bool> as RadioPromiscuousMode;
    interface Leds;
    interface Ieee802154Debug as Debug;
  }
}
implementation
{

/* ----------------------- RadioRx ----------------------- */

  async command error_t MacRx.prepare[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRx.prepare();
    else {
      call Leds.led0On();
      return FAIL;
    } 
  }
    
  async event void PhyRx.prepareDone()
  {
    signal MacRx.prepareDone[call ArbiterInfo.userId()]();
  }

  async command bool MacRx.isPrepared[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRx.isPrepared();
    else {
      call Leds.led0On();
      return FAIL;
    } 
  }

  async command error_t MacRx.receive[uint8_t client](ieee154_reftime_t *t0, uint32_t dt)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyRx.receive(t0, dt);
    else {
      call Leds.led0On();
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  event message_t* PhyRx.received(message_t *msg, ieee154_reftime_t *timestamp)
  {
    uint8_t *mhr = MHR(msg);
    if (((mhr[1] & FC2_FRAME_VERSION_MASK) > FC2_FRAME_VERSION_1)
        && (!call RadioPromiscuousMode.get()))
      return msg;
#ifndef IEEE154_SECURITY_ENABLED
    if ((mhr[0] & FC1_SECURITY_ENABLED)
        && (!call RadioPromiscuousMode.get()))
      return msg;
#endif
    return signal MacRx.received[call ArbiterInfo.userId()](msg, timestamp);
  }

  async command bool MacRx.isReceiving[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRx.isReceiving();
    else {
      call Leds.led0On();
      return FAIL;
    } 
  }

/* ----------------------- RadioTx ----------------------- */

  async command error_t MacTx.load[uint8_t client](ieee154_txframe_t *frame)
  {
    if (client == call ArbiterInfo.userId())
      return call PhyTx.load(frame);
    else {
      call Leds.led0On();
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }
    
  async event void PhyTx.loadDone()
  {
    signal MacTx.loadDone[call ArbiterInfo.userId()]();
  }

  async command ieee154_txframe_t* MacTx.getLoadedFrame[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyTx.getLoadedFrame();
    else {
      call Leds.led0On();
      return NULL;
    }
  }

  async command error_t MacTx.transmit[uint8_t client](ieee154_reftime_t *t0, uint32_t dt)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyTx.transmit(t0, dt);
    else {
      call Leds.led0On();
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }
  
  async event void PhyTx.transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime)
  {
    signal MacTx.transmitDone[call ArbiterInfo.userId()](frame, txTime);
  }

  async command error_t MacTx.transmitUnslottedCsmaCa[uint8_t client](ieee154_csma_t *csmaParams)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyTx.transmitUnslottedCsmaCa(csmaParams);
    else {
      call Leds.led0On();
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async event void PhyTx.transmitUnslottedCsmaCaDone(ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
    signal MacTx.transmitUnslottedCsmaCaDone[call ArbiterInfo.userId()](
        frame, ackPendingFlag, csmaParams, result);
  }

  async command error_t MacTx.transmitSlottedCsmaCa[uint8_t client](ieee154_reftime_t *slot0Time, uint32_t dtMax, 
      bool resume, uint16_t remainingBackoff, ieee154_csma_t *csmaParams)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyTx.transmitSlottedCsmaCa(slot0Time, dtMax, resume, remainingBackoff, csmaParams);
    else {
      call Leds.led0On();
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async event void PhyTx.transmitSlottedCsmaCaDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, uint16_t remainingBackoff, ieee154_csma_t *csmaParams, error_t result)
  {
    signal MacTx.transmitSlottedCsmaCaDone[call ArbiterInfo.userId()](
        frame, txTime, ackPendingFlag, remainingBackoff, csmaParams, result);
  }

/* ----------------------- RadioOff ----------------------- */

  async command error_t MacRadioOff.off[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRadioOff.off();
    else {
      call Leds.led0On();
      return EBUSY;
    }
  }

  async event void PhyRadioOff.offDone()
  {
    signal MacRadioOff.offDone[call ArbiterInfo.userId()]();
  }

  
  async command bool MacRadioOff.isOff[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRadioOff.isOff();
    else
      return EBUSY;
  }

/* ----------------------- Defaults ----------------------- */

  default async event void MacTx.loadDone[uint8_t client]()
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 0, 0, 0, 0);
  }
  default async event void MacTx.transmitDone[uint8_t client](ieee154_txframe_t *frame, ieee154_reftime_t *txTime) 
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 1, 0, 0, 0);
  }
  default async event void MacRx.prepareDone[uint8_t client]()
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 2, 0, 0, 0);
  }
  default event message_t* MacRx.received[uint8_t client](message_t *frame, ieee154_reftime_t *timestamp)
  {
    call Debug.log(DEBUG_LEVEL_IMPORTANT, 3, client, call ArbiterInfo.userId(), 0xff);
    return frame;
  }
  default async event void MacRadioOff.offDone[uint8_t client]()
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 4, 0, 0, 0);
  }
  default async event void MacTx.transmitUnslottedCsmaCaDone[uint8_t client](ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 5, 0, 0, 0);
  }
  default async event void MacTx.transmitSlottedCsmaCaDone[uint8_t client](ieee154_txframe_t *frame, 
      ieee154_reftime_t *txTime, bool ackPendingFlag, uint16_t remainingBackoff, 
      ieee154_csma_t *csmaParams, error_t result)
  {
    call Debug.log(DEBUG_LEVEL_CRITICAL, 6, 0, 0, 0);
  }
}
