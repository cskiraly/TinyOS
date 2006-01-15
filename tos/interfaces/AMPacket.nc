// $Id: AMPacket.nc,v 1.1.2.7 2006-01-15 22:31:32 scipio Exp $
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

/**
  * The Active Message accessors, which provide the AM local address and
  * functionality for querying packlets. Also see the Packet interface.
  *
  * @author Philip Levis
  * @date   January 5 2005
  */ 


#include <message.h>
#include <AM.h>

interface AMPacket {

  /**
   * Return the AM address of this mote.
   *
   */

  command am_addr_t address();

  /**
   * Return the AM address of the destination field of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   */
  
  command am_addr_t destination(message_t* amsg);

  /**
   * Return whether <tt>amsg</tt> is destined for this mote. This is
   * partially a shortcut for testing whether the return value of
   * <tt>destination</tt> and <tt>address</tt> are the same. It
   * may, however, include additional logic. For example, there
   * may be an AM broadcast address: <tt>destination</tt> will return
   * the broadcast address, but <tt>address</tt> will still be
   * the mote's local address. If <tt>amsg</tt> is not an AM packet,
   * the results of this command are undefined.
   */
  command bool isForMe(message_t* amsg);
  
  /**
   * Return the AM type of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   */
  
  command am_id_t type(message_t* amsg);

  /**
   * Return the AM local group of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   */
  
  //  command am_group_t group(message_t* amsg);

}
