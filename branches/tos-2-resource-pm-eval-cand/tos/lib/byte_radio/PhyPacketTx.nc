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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2006-01-31 12:25:32 $
 * ========================================================================
 */

/**
 * Physical Packet Transmission Interface.
 * Commands and event provided by the Physical Layer
 * to communicate with upper layers about the status of a 
 * packet that is being transmitted.
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de)>
 */  
 
interface PhyPacketTx {
  /**
  * Cancel the current packet transmission.
  *
  * @return SUCCESS if we are actually sending a packet
  *         FAIL otherwise.
  */
  async command error_t cancel();
  
  /**
  * Start sending a new packet header. 
  */
  async command void sendHeader();
  
  /**
  * Notification that the packet header was sent.
  *
  * @param error Success-Notification.
  */
  async event void sendHeaderDone(error_t error);
  
  /**
  * Start sending the packet footer.
  */
  async command void sendFooter();
  
  /**
  * Notification that the the packet footer was sent.
  *
  * @param error Success-Notification.
  */
  async event void sendFooterDone(error_t error);  
}