/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Access to the CC2420 RXFIFO and TXFIFO memories.
 * @author Alan Broad
 */

includes CC2420Const;

module CC2420FifoP {
  provides {
    interface CC2420Fifo;
  }
  uses {
    interface GeneralIO as CC_CS;
    interface SPIPacket as Packet;
  }
}
implementation
{
  norace bool bSpiAvail;                    //true if Spi bus available
  norace uint8_t* txbuf; uint8_t* rxbuf;
  norace uint8_t txlength, rxlength; 
  bool rxbufBusy, txbufBusy;


  task void signalTXdone() {
    uint8_t tmpLen;
    uint8_t* tmpBuf;

    atomic {
      tmpLen = txlength;
      tmpBuf = txbuf;
      txbufBusy = FALSE;
    }

    signal CC2420Fifo.writeTxFifoDone(tmpBuf, tmpLen, SUCCESS);
  }

  task void signalRXdone() {
    uint8_t tmpLen;
    uint8_t* tmpBuf;

    atomic {
      tmpLen = rxlength;
      tmpBuf = rxbuf;
      rxbufBusy = FALSE;
    }

    signal CC2420Fifo.readRxFifoDone(tmpBuf, tmpLen, SUCCESS);
  }

  /**
   * Writes a series of bytes to the transmit FIFO.
   *
   * @param length nof bytes be written
   * @param msg pointer to first byte of data
   *
   * @return SUCCESS if the bus is free to write to the FIFO
   */
  async command error_t CC2420Fifo.writeTxFifo(uint8_t* buf, uint8_t len) {
     uint8_t i = 0;
     uint8_t status;
     bool returnFail = FALSE;

     atomic {
       if (txbufBusy)
	 returnFail = TRUE;
       else
	 txbufBusy = TRUE;
     }

     if (returnFail) {
       return FAIL;
     }

 //   while (!bSpiAvail){};                      //wait for spi bus 

     atomic {
       bSpiAvail = FALSE;
       txlength = len;
       txbuf = buf;
       call CC_CS.clr();                   //enable chip select
       SPDR = CC2420_TXFIFO;
       while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
       status = SPDR;
       for (i=0; i < txlength; i++){
	 SPDR = *txbuf;
	 txbuf++;
	 while (!(SPSR & 0x80)){};  //wait for spi xfr to complete
       }
       bSpiAvail = TRUE;
     }  //atomic
     call CC_CS.set();                       //disable chip select
     if (post signalTXdone() == FAIL) {
       atomic txbufBusy = FALSE;
       return FAIL;
     }
     if (status) {
       return SUCCESS;
     }
     else {
       return FAIL;
     }
  }
  
  /**
   * Read from the RX FIFO queue.  Will read bytes from the queue
   * until the length is reached (determined by the first byte read).
   * RXFIFODone() is signalled when all bytes have been read or the
   * end of the packet has been reached.
   *
   * @param length number of bytes requested from the FIFO
   * @param data buffer bytes should be placed into
   *
   * @return SUCCESS if the bus is free to read from the FIFO
   */
  async command error_t CC2420Fifo.readRxFifo(uint8_t *buf, uint8_t len) {
     uint8_t status,i;
     bool returnFail = FALSE;
     atomic {
       if (rxbufBusy)
	 returnFail = TRUE;
       else
	 rxbufBusy = TRUE;
     }
     
     if (returnFail)
       return FAIL;

 //   while (!bSpiAvail){};                      //wait for spi bus 

     atomic {
       bSpiAvail = FALSE;
       atomic rxbuf = buf;
       call CC_CS.clr();                   //enable chip select
       SPDR = CC2420_RXFIFO | 0x40;       //output Rxfifo address
       while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
       status = SPDR;
       SPDR = 0;
       while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
       rxlength = SPDR;
       if( rxlength > 0 ) {
	 rxbuf[0] = rxlength;
	 // total length including the length byte
	 rxlength++;
	 // protect against writing more bytes to the buffer than we have
	 if (rxlength > len) rxlength = len;
	 
	 for (i=1; i < rxlength ; i++){ 
	   SPDR = 0;
	   while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
	   rxbuf[i] = SPDR;
	 } //i
       }//rxlength>0
       
       bSpiAvail = TRUE;
     } //atomic
     call CC_CS.set();                       //disable chip select
     if (post signalRXdone() == FAIL) {
       atomic rxbufBusy = FALSE;
       return FAIL;
     }
     return SUCCESS;	  //return also indicates completion...
  }// readRXFIFO

   async event void Packet.sendDone(uint8_t* data, uint8_t* rxBuf, uint8_t len, error_t err) {
    
  }

 default async void event CC2420Fifo.writeTxFifoDone(uint8_t* data, uint8_t len, error_t err) {}

 default async void event CC2420Fifo.readRxFifoDone(uint8_t* data, uint8_t len, error_t err) {}
} //module



