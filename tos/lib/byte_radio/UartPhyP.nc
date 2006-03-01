/*
* Copyright (c) 2004, Technische Universitaet Berlin
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
* - Description ---------------------------------------------------------
*
* - Revision -------------------------------------------------------------
* $Revision: 1.1.2.3 $
* $Date: 2006-03-01 18:38:17 $
* @author: Kevin Klues (klues@tkn.tu-berlin.de)
* @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
* ========================================================================
*/

/**
 * UartPhyP module
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */
module UartPhyP {
provides {
  interface Init;
  interface PhyPacketTx;
  interface RadioByteComm as SerializerRadioByteComm;
  interface PhyPacketRx;
}
uses {
  interface RadioByteComm;
}
}
implementation
{
  /* Module Definitions  */
  typedef enum {
    STATE_NULL,
    STATE_PREAMBLE,
    STATE_SYNC,
    STATE_SFD,
    STATE_HEADER_DONE,
    STATE_DATA,
    STATE_FOOTER_START,
    STATE_FOOTER_DONE,
    STATE_CANCEL_HEADER,
    STATE_CANCEL_DATA,
    STATE_CANCEL_FOOTER
  } phyState_t;

#define PREAMBLE_LENGTH   4
#define PREAMBLE_BYTE     0x55
#define SYNC_BYTE         0xFF
#define SFD_BYTE          0x33

/** Module Global Variables  */
phyState_t phyState;    // Current Phy state State
uint16_t numPreambles;  // Number of preambles to send before the packet

    /* Local Function Declarations */
    void TransmitNextByte();
    void ReceiveNextByte(uint8_t data);

    /* Radio Init */
    command error_t Init.init(){
      atomic {
        atomic phyState = STATE_NULL;
      }
      return SUCCESS;
    }

    async command void PhyPacketTx.sendHeader() {
      atomic {
        phyState = STATE_PREAMBLE;
        numPreambles = PREAMBLE_LENGTH;
      }
      TransmitNextByte();
    }

    async command void SerializerRadioByteComm.txByte(uint8_t data) {
      call RadioByteComm.txByte(data);
    }

    async command bool SerializerRadioByteComm.isTxDone() {
      return call RadioByteComm.isTxDone();
    }

    async command void PhyPacketTx.sendFooter() {
      atomic phyState = STATE_FOOTER_START;
      TransmitNextByte();
    }


    /* Radio Recv */
    async command void PhyPacketRx.recvHeader() {
      atomic phyState = STATE_PREAMBLE;
    }

    async command void PhyPacketRx.recvFooter() {
        // currently there is no footer
        // atomic phyState = STATE_FOOTER_START;
        atomic phyState = STATE_NULL;
        signal PhyPacketRx.recvFooterDone(TRUE);
    }

    async command error_t PhyPacketTx.cancel() {
      switch(phyState) {
        case STATE_PREAMBLE:
        case STATE_SYNC:
        case STATE_SFD:
        case STATE_HEADER_DONE:
          atomic phyState = STATE_CANCEL_HEADER;
          return SUCCESS;
        case STATE_DATA:
          atomic phyState = STATE_CANCEL_DATA;
          return SUCCESS;
        case STATE_FOOTER_START:
          atomic phyState = STATE_CANCEL_FOOTER;
          return SUCCESS;
        default:
          return FAIL;
      }
    }

    /* Tx Done */
    async event void RadioByteComm.txByteReady(error_t error) {
      phyState_t state;
      if(error == SUCCESS) {
        TransmitNextByte();
      }
      else {
        atomic state = phyState;
        switch(state) {
          case STATE_PREAMBLE:
          case STATE_SYNC:
          case STATE_SFD:
            signal PhyPacketTx.sendHeaderDone(error);
            break;
          case STATE_DATA:
          case STATE_FOOTER_START:
            signal PhyPacketTx.sendFooterDone(error);
            break;
          default:
            signal SerializerRadioByteComm.txByteReady(error);
            break;
        }
      }
    }

    void TransmitNextByte() {
      phyState_t state;
      atomic state = phyState;
      switch(state) {
        case STATE_PREAMBLE:
          atomic {
            if(numPreambles > 0) {
              numPreambles--;
            } else {
              phyState = STATE_SYNC;
            }
          }
          call RadioByteComm.txByte(PREAMBLE_BYTE);
          break;
        case STATE_SYNC:
          atomic phyState = STATE_SFD;
          call RadioByteComm.txByte(SYNC_BYTE);
          break;
        case STATE_SFD:
          atomic phyState = STATE_HEADER_DONE;
          call RadioByteComm.txByte(SFD_BYTE);
          break;
        case STATE_HEADER_DONE:
          atomic phyState = STATE_DATA;
          signal PhyPacketTx.sendHeaderDone(SUCCESS);
          break;
        case STATE_DATA:
          signal SerializerRadioByteComm.txByteReady(SUCCESS);
          break;
        case STATE_FOOTER_START:
                        // maybe there will be a time.... we will need this.
                        // atomic phyState = STATE_FOOTER_DONE;
                        // break;
        case STATE_FOOTER_DONE:
          atomic phyState = STATE_NULL;
          signal PhyPacketTx.sendFooterDone(SUCCESS);
          break;
        case STATE_CANCEL_HEADER:
          atomic phyState = STATE_NULL;
          signal PhyPacketTx.sendHeaderDone(ECANCEL);
          break;
        case STATE_CANCEL_DATA:
          atomic phyState = STATE_NULL;
          signal SerializerRadioByteComm.txByteReady(ECANCEL);
          break;
        case STATE_CANCEL_FOOTER:
          atomic phyState = STATE_NULL;
          signal PhyPacketTx.sendFooterDone(ECANCEL);
        default:
          break;
      }
    }

    /* Rx Done */
    async event void RadioByteComm.rxByteReady(uint8_t data) {
      ReceiveNextByte(data);
    }

    /* Receive the next Byte from the USART */
    void ReceiveNextByte(uint8_t data) {
      switch(phyState) {
        case STATE_PREAMBLE:

          if(data == PREAMBLE_BYTE) {
            atomic phyState = STATE_SYNC;
          } else {
            atomic phyState = STATE_PREAMBLE;
          }
          break;
        case STATE_SYNC:
          if(data != PREAMBLE_BYTE) {
            if (data == SFD_BYTE) {
              signal PhyPacketRx.recvHeaderDone();
              atomic phyState = STATE_DATA;
            }
            else atomic phyState = STATE_SFD;
          }
          break;
        case STATE_SFD:
          if (data == SFD_BYTE) {
            signal PhyPacketRx.recvHeaderDone();
            atomic phyState = STATE_DATA;
          } else {
            atomic phyState = STATE_PREAMBLE;
          }
          break;
        case STATE_DATA:
          signal SerializerRadioByteComm.rxByteReady(data);
          break;
          // maybe there will be a time.... we will need this. but for now there is no footer
          //              case STATE_FOOTER_START:
          //                      atomic phyState = STATE_FOOTER_DONE;
          //                      break;
          //              case STATE_FOOTER_DONE:
          //                      atomic phyState = STATE_NULL;
          //                      signal PhyPacketRx.recvFooterDone(TRUE);
          //                      break;
        default:
          break;
      }
    }
}
