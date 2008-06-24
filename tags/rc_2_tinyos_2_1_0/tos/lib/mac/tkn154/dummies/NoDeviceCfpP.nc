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
 * $Date: 2008-06-18 15:52:53 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * The contention free period (CFP) in beacon mode, a.k.a. GTS, is not yet
 * implemented - this is only an empty placeholder. In contrast to the CAP
 * component the GTS component for an incoming superframe will probably be very
 * different from the GTS for an outgoing superframe. That is why there are two
 * separate placeholder components (DeviceCfpP and CoordCfpP) instead of one
 * generic CfpP component. This component would deal with the GTS for an
 * incoming superframe, i.e. from the perspective of a device.
 */

#include "TKN154_MAC.h"
module NoDeviceCfpP
{
  provides {
    interface Init;
    interface FrameTx as CfpTx;
    interface Purge;
  } uses {
    interface Resource as Token;
    interface ResourceTransferred as TokenTransferred;
    interface ResourceRequested as TokenRequested;
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CfpEnd; 
    interface GetNow<uint8_t*> as GtsField; 
    interface GetNow<uint32_t> as SfSlotDuration; 
    interface GetNow<uint8_t> as FinalCapSlot; 
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpSlotAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpEndAlarm;
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface MLME_GET;
    interface MLME_SET;
  }
}
implementation
{
  command error_t Init.init()
  {
    // initialize any module variables
    return SUCCESS;
  }

  command ieee154_status_t CfpTx.transmit(ieee154_txframe_t *data)
  {
    // request to send a frame in a GTS slot (triggered by MCPS_DATA.request())
    return IEEE154_INVALID_GTS;
  }

  command ieee154_status_t Purge.purge(uint8_t msduHandle)
  {
    // request to purge a frame (triggered by MCPS_DATA.purge())
    return IEEE154_INVALID_HANDLE; 
  } 

  event void TokenTransferred.transferred()
  { 
    // the CFP has started, this component now owns the token -  
    // because GTS is not implemented we release the token
    // immediately; the general rule is: as long as a component
    // owns the token it has exclusive access to the radio
    call Token.release();
  }

  async event void CfpEndAlarm.fired() { }

  async event void CfpSlotAlarm.fired() {}

  async event void RadioOff.offDone()
  {
    call Token.release();
  }

  async event void RadioTx.loadDone(){}
  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, 
      ieee154_reftime_t *referenceTime, bool ackPendingFlag, error_t error){}

  async event void RadioRx.prepareDone(){} 
  event message_t* RadioRx.received(message_t *frame, ieee154_reftime_t *timestamp){return frame;}

  async event void TokenRequested.requested()
  {
    // someone requested access to the radio, you might
    // consider releasing it...
  }

  async event void TokenRequested.immediateRequested(){ }
  event void Token.granted(){ }
}
