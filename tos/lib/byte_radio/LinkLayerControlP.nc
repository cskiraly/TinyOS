/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
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
 * - Description --------------------------------------------------------
 * Implementation of Link Layer for PreambleSampleMAC
 *
 * This Link layer assumes
 *  - link speed on air is 19200 bit/s
 *  - a marshaller that handles packet reception, including timeouts
 *  - the sleep time to be around 100 ms
 *  - the wake time to be around 6ms
 *  - a MAC that handles busy channels and sleeping of the radio
 *  
 * This link layer provides:
 *  - adaptation of preamble length based on packet type (unicast with
 *    a preamble of full length, broadcast with reduced length)
 *  - strength field in dB (rather than some
 *    hardware specific measure), assuming a gradient of 14mv/dB
 *  - no retransmissions
 *  
 * - Author -------------------------------------------------------------
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "radiopacketfunctions.h"
#include "message.h"

module LinkLayerControlP {
    provides {
      interface Init;
      interface SplitControl;
      interface Receive;
      interface Send;
      interface PacketAcknowledgements;
    }
    uses {
      interface SplitControl as MacSplitControl;
      interface SplitControl as RadioSplitControl;
      interface Send as SendDown;
      interface Receive as ReceiveLower;
    }
}
implementation
{
// #define LLCM_DEBUG
        
    uint8_t seqNo;              // for later use ...
    error_t splitStateError;    // state of SplitControl interfaces
    
    
    /**************** Helper functions ******/
    void signalFailure() {
#ifdef LLCM_DEBUG
        atomic {
            for(;;) {
                ;
            }
        }
#endif
    }
    
    /**************** Init  *****************/
    command error_t Init.init(){
        atomic {
            seqNo = 0;
            splitStateError = EOFF;
        }
        return SUCCESS;
    }

    /**************** Start  *****************/
    void checkStartDone(error_t error) {
      atomic {
        if ( (splitStateError == SUCCESS) && (error == SUCCESS) ) {
          signal SplitControl.startDone(SUCCESS);
        } else if ( (error == SUCCESS) && (splitStateError == EOFF) ) {
          splitStateError = SUCCESS;
        } else {
          signal SplitControl.startDone(FAIL);
        }
      }
    }
    
    event void MacSplitControl.startDone(error_t error) {
      checkStartDone(error);
    }
    
    event void RadioSplitControl.startDone(error_t error) {
      checkStartDone(error);
    }
    
    command error_t SplitControl.start() {
      call MacSplitControl.start();
      call RadioSplitControl.start();
      return SUCCESS;
    }
    /**************** Stop  *****************/
    void checkStopDone(error_t error) {
      atomic {
        if ( (splitStateError == SUCCESS) && (error == EOFF) ) {
          signal SplitControl.stopDone(SUCCESS);
        } else if ( (error == SUCCESS) && (splitStateError == SUCCESS) ) {
          splitStateError = EOFF;
        } else {
          signal SplitControl.stopDone(FAIL);
        }
      }
    }
    
    event void MacSplitControl.stopDone(error_t error) {
      checkStopDone(error);
    }
    
    event void RadioSplitControl.stopDone(error_t error) {
      checkStopDone(error);
    }
    
    command error_t SplitControl.stop(){
      call MacSplitControl.stop();
      call RadioSplitControl.stop();
      return SUCCESS;
    }
    /**************** Send ****************/
    command error_t Send.send(message_t *msg, uint8_t len) {
      ++seqNo;  // where to put?
      return call SendDown.send(msg, len);
    }

    command error_t Send.cancel(message_t* msg) {
      return call SendDown.cancel(msg);
    }
    
    command uint8_t Send.maxPayloadLength() {
      return call SendDown.maxPayloadLength();
    }

    command void* Send.getPayload(message_t* msg) {
      return call SendDown.getPayload(msg);
    }
    
    event void SendDown.sendDone(message_t* sent, error_t result) { 
        atomic {
          getMetadata(sent)->ack = 1; // this is rather stupid
        }
        signal Send.sendDone(sent, result);
    }
    
    /*************** Receive ***************/

    event message_t* ReceiveLower.receive(message_t* msg, void* payload, uint8_t len) {
        msg = signal Receive.receive(msg, payload, len);
        return msg;
    }
    
    command void* Receive.getPayload(message_t* msg, uint8_t* len) {
      return call ReceiveLower.getPayload(msg, len);
    }

    command uint8_t Receive.payloadLength(message_t* msg) {
      return call ReceiveLower.payloadLength(msg);
    }

    /*************** default events ***********/

    /* for lazy buggers who do not want to do something with a packet */
    default event void Send.sendDone(message_t* sent, error_t success) {
    }

    default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        return msg;
    }     
    
    
    /* PacketAcknowledgements interface */

    async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
      return FAIL;
    }

    async command error_t PacketAcknowledgements.noAck(message_t* msg) {
      return SUCCESS;
    }

    async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
      return FALSE;
    }

    
    
    
    
}



