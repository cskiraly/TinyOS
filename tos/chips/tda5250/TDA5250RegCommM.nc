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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-30 21:14:36 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module TDA5250RegCommM {
  provides {
    interface Init;
    interface TDA5250RegComm;
  }
  uses {
    interface GeneralIO as BUSM;
    interface SPIByte;
  }
}

implementation {

   uint8_t txBuf[3];
	 uint8_t rxBuf[1];
   
   command error_t Init.init() {
     // setting pins to output
     call BUSM.makeOutput();
     
     //initializing pin values
     call BUSM.set();  //Use SPI for writing to Regs
     return SUCCESS;
   } 

   async command error_t TDA5250RegComm.writeByte(uint8_t address, uint8_t data) {
      call SPIByte.tx(address);
      call SPIByte.tx(data);
      return SUCCESS;
   } 

   async command error_t TDA5250RegComm.writeWord(uint8_t address, uint16_t data) {        
      call SPIByte.tx(address);
      call SPIByte.tx((uint8_t) (data >> 8));
      call SPIByte.tx((uint8_t) data);
      return SUCCESS;
   }

   async command uint8_t TDA5250RegComm.readByte(uint8_t address){
      call SPIByte.tx(address);
      return call SPIByte.tx(0x00);  
   }
}
