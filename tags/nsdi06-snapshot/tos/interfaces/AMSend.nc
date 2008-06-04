// $Id: AMSend.nc,v 1.1.2.3 2005-03-14 03:54:19 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/** The basic active message message sending interface. Also see
  * Packet, Receive, and Send.
  *
  * @author Philip Levis
  * @date   January 5 2005
  */ 


includes TinyError;
includes TOSMsg;
includes AM;

interface AMSend {

  /** 
    * Send a packet with a data payload of <tt>len</tt> to address
    * <tt>addr</tt>. To determine the maximum available size, use the
    * Packet interface of the component providing AMSend. If send
    * returns SUCCESS, then the component will signal the sendDone
    * event in the future; if send returns an error, it will not
    * signal the event.  Note that a component may accept a send
    * request which it later finds it cannot satisfy; in this case, it
    * will signal sendDone with error code.
    */ 
  command error_t send(am_addr_t addr, message_t* msg, uint8_t len);

  /**
    * Cancel a requested transmission. Returns SUCCESS if the 
    * transmission was canceled properly (not sent in its
    * entirety). Note that the component may not know
    * if the send was successfully canceled, if the radio is
    * handling much of the logic; in this case, a component
    * should be conservative and return an appropriate error code.
    * A successful call to cancel must always result in a 
    * sendFailed event, and never a sendSucceeded event.
    */
  command error_t cancel(message_t* msg);

  /** 
    * Signaled in response to an accepted send request. <tt>msg</tt> is
    * the message buffer sent, and <tt>error</tt> indicates whether
    * the send was successful.
    *
    */ 

  event void sendDone(message_t* msg, error_t error);

}