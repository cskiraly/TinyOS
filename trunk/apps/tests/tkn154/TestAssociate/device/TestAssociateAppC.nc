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
 * $Date: 2008-07-21 14:56:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

configuration TestAssociateAppC
{
} implementation {
  components MainC, LedsC, Ieee802154MacC as Ieee802154MacC,
             new Timer62500C() as Timer;
  components TestDeviceC as App;

  MainC.Boot <- App;
  App.Leds -> LedsC;
  App.MLME_RESET -> Ieee802154MacC;
  App.MLME_SET -> Ieee802154MacC;
  App.MLME_GET -> Ieee802154MacC;
  App.DisassociateTimer -> Timer;  
  App.MLME_SCAN -> Ieee802154MacC;
  App.MLME_SYNC -> Ieee802154MacC;
  App.MLME_BEACON_NOTIFY -> Ieee802154MacC;
  App.MLME_SYNC_LOSS -> Ieee802154MacC;
  App.MLME_ASSOCIATE -> Ieee802154MacC;
  App.MLME_DISASSOCIATE -> Ieee802154MacC;
  App.MLME_COMM_STATUS -> Ieee802154MacC;
  App.BeaconFrame -> Ieee802154MacC;

}
