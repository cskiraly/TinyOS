// $Id: Send.nc,v 1.1.2.6 2005-03-14 03:51:48 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2004-5 The Regents of the University  of California.  
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
 * Copyright (c) 2004-5 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/** The basic message sending interface. Also see Packet and Receive.
  *
  * @author Philip Levis
  * @date   January 5 2005
  */ 


includes TinyError;
includes TOSMsg;

interface Send {

  /** 
    * Send a packet with a data payload of <tt>len</tt>. To determine
    * the maximum available size, use the Packet interface of the
    * component providing Send. If send returns SUCCESS, then the
    * component will signal the sendDone event in the future; if send
    * returns an error, it will not signal sendDone.  Note that a
    * component may accept a send request which it later finds it
    * cannot satisfy; in this case, it will signal sendDone with an
    * appropriate error code.
    */ 
  command error_t send(message_t* msg, uint8_t len);

  /**
    * Cancel a requested transmission. Returns SUCCESS if the 
    * transmission was cancelled properly (not sent in its
    * entirety). Note that the component may not know
    * if the send was successfully cancelled, if the radio is
    * handling much of the logic; in this case, a component
    * should be conservative and return an appropriate error code.
    * A successful call to cancel must always result in a 
    * sendFailed event, and never a sendSucceeded event.
    */
  command error_t cancel(message_t* msg);

  /** 
    * Signaled in response to an accepted send request. <tt>msg</tt>
    * is the sent buffer, and <tt>error</tt> indicates whether the
    * send was succesful, and if not, the cause of the failure.
    */ 
  event void sendDone(message_t* msg, error_t error);

}
