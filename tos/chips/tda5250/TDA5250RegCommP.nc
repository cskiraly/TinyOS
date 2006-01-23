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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-23 00:54:44 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module TDA5250RegCommP {
  provides {
    interface Init;
    interface TDA5250RegComm;
    // FIXME: Hier ResourceController!?
    interface Resource;
  }
  uses {
    interface GeneralIO as BusM;
    // FIXME: Hier ResourceController als high priority client!?
    interface Resource as SpiResource;
//    interface ArbiterInfo;
    interface SPIByte;
  }
}

implementation {

   command error_t Init.init() {
     // setting pins to output
     call BusM.makeOutput();

     //initializing pin values
     call BusM.set();  //Use SPI for writing to Regs

     return SUCCESS;
   }

   async command error_t Resource.request() {
     return call SpiResource.request();
   }

   async command error_t Resource.immediateRequest() {
     if(call SpiResource.immediateRequest() == EBUSY)
       return EBUSY;
     return SUCCESS;
   }

   async command uint8_t Resource.getId() {
   //  return TDA5250_SPI_BUS_ID;
   return 255;
   }

   async command void Resource.release() {
     call SpiResource.release();
   }

   event void SpiResource.granted() {
     signal Resource.granted();
   }

   /* FIXME
   event void SpiResource.requested() {
     signal Resource.requested();
   }


   async event void Usart.txDone() {
   }
   async event void Usart.rxDone(uint8_t data) {
   }
*/
   async command error_t TDA5250RegComm.writeByte(uint8_t address, uint8_t data) {
     uint8_t rxbyte;
//     if(call ArbiterInfo.userId() != TDA5250_SPI_BUS_ID) {
//       return FAIL;
//     }
     call SPIByte.write(address,&rxbyte);
     call SPIByte.write(data,&rxbyte);
     return SUCCESS;
   }
   async command error_t TDA5250RegComm.writeWord(uint8_t address, uint16_t data) {
      uint8_t rxbyte;
//      if(call ArbiterInfo.userId() != TDA5250_SPI_BUS_ID)
//        return FAIL;
      call SPIByte.write(address, &rxbyte);
      call SPIByte.write(((uint8_t) (data >> 8)),&rxbyte);
      call SPIByte.write(((uint8_t) data),&rxbyte);
      return SUCCESS;
   }

   async command uint8_t TDA5250RegComm.readByte(uint8_t address){
      uint8_t rxbyte;
//      if(call ArbiterInfo.userId() != TDA5250_SPI_BUS_ID)
//        return 0x00;
      call SPIByte.write(address, &rxbyte);

      // FIXME: Put SIMO/SOMI in input
      call SPIByte.write(0x00, &rxbyte);
      return rxbyte;
   }

}
