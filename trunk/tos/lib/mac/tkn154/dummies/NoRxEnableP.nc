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
 * $Date: 2008-10-23 16:09:28 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
module NoRxEnableP
{
  provides
  {
    interface Init;
    interface MLME_RX_ENABLE;
    interface GetNow<bool> as IsRxEnableActive; 
    interface Notify<bool> as RxEnableStateChange;
  }
  uses
  {
    interface Ieee802154Debug as Debug;
    interface Timer<TSymbolIEEE802154> as RxEnableTimer;
    interface GetNow<bool> as IsBeaconEnabledPAN;
    interface Get<ieee154_macPanCoordinator_t> as IsMacPanCoordinator;
    interface GetNow<bool> as IsTrackingBeacons;
    interface GetNow<uint32_t> as IncomingSfStart; 
    interface GetNow<uint32_t> as IncomingBeaconInterval; 
    interface GetNow<bool> as IsSendingBeacons;
    interface GetNow<uint32_t> as OutgoingSfStart; 
    interface GetNow<uint32_t> as OutgoingBeaconInterval; 
    interface Notify<bool> as WasRxEnabled;
    interface TimeCalc;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS; }

/* ----------------------- MLME-RX-ENABLE ----------------------- */

  command ieee154_status_t MLME_RX_ENABLE.request  ( 
                          bool DeferPermit,
                          uint32_t RxOnTime,
                          uint32_t RxOnDuration
                        )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void RxEnableTimer.fired() {}

  async command bool IsRxEnableActive.getNow() { return FALSE; }

  event void WasRxEnabled.notify( bool val ) { }

  command error_t RxEnableStateChange.enable(){return FAIL;}
  command error_t RxEnableStateChange.disable(){return FAIL;}
  default event void MLME_RX_ENABLE.confirm(ieee154_status_t status){}
}
