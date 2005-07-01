// $Id: RadioByteComm.nc,v 1.1.2.1 2005-07-01 13:08:40 klueska Exp $

/*									tab:4
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
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 */

/**
 * A byte-level communication interface. It signals byte receptions and
 * provides a split-phased byte send interface. txByteReady states
 * that the component can accept another byte in its queue to send,
 * while txDone states that the send queue has been emptied.
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */
interface RadioByteComm {
  /**
   * Transmits a byte over the radio
   *
   * @param data the byte to be transmitted
   *
   * @return SUCCESS if successful
   */
  async command void txByte(uint8_t data);
	
  /**
   * Notification that the radio is ready to receive another byte
   *
   * @param data the byte read from the radio
   *
   * @return SUCCESS if successful
   */
  async event void rxByteReady(uint8_t data);

  /**
   * Notification that the bus is ready to transmit/queue another byte
   *
   * @param success Notification of the successful transmission of the last byte
   *
   * @return SUCCESS if successful
   */
  async event void txByteReady(error_t error);

  /**
   * Check to see if the transmission is done and the queue is empty
   *
   * @return TRUE if the queue is empty and no more bytes will be sent
	 *         FALSE if bytes remain in the queue
   */
  async command bool isTxDone();
}
