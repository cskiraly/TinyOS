/*
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 */
 
/** 
  * The basic address-free message sending interface in asnyc context. 
  *
  * This interface provides similar functionality as the Send interface
  * but is provided by the MAC layer. 
  *
  * @author Philipp Huppertz
  * @date   March 21 2006
  * @see    Send
  */ 



#include <TinyError.h>
#include <message.h>

interface MacSend {

    /** 
    * Send a packet with a data payload of <tt>len</tt>. To determine
    * the maximum available size, use the Packet interface of the
    * component providing Send. If send returns SUCCESS, then the
    * component will signal the sendDone event in the future; if send
    * returns an error, it will not signal sendDone.  Note that a
    * component may accept a send request which it later finds it
    * cannot satisfy; in this case, it will signal sendDone with an
    * appropriate error code.
    *
    * @param   msg     the packet to send
    * @param   len     the length of the packet payload
    * @return          SUCCESS if the request was accepted and will issue
    *                  a sendDone event, EBUSY if the component cannot accept
    *                  the request now but will be able to later, FAIL
    *                  if the stack is in a state that cannot accept requests
    *                  (e.g., it's off).
    */ 
  async command error_t send(message_t* msg, uint8_t len);
  
  /**
  * Cancel a requested transmission. Returns SUCCESS if the 
  * transmission was cancelled properly (not sent in its
  * entirety). Note that the component may not know
  * if the send was successfully cancelled, if the radio is
  * handling much of the logic; in this case, a component
  * should be conservative and return an appropriate error code.
  *
  * @param   msg    the packet whose transmission should be cancelled
  * @return         SUCCESS if the packet was successfully cancelled, FAIL
  *                 otherwise
  */
  async command error_t cancel(message_t* msg);

  /** 
  * Signaled in response to an accepted send request. <tt>msg</tt>
  * is the sent buffer, and <tt>error</tt> indicates whether the
  * send was succesful, and if not, the cause of the failure.
  * 
  * @param msg   the message which was requested to send
  * @param error SUCCESS if it was transmitted successfully, FAIL if
  *              it was not, ECANCEL if it was cancelled via <tt>cancel</tt>
  */ 
  async event void sendDone(message_t* msg, error_t error);
}