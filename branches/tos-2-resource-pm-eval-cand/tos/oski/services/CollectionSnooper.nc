// $Id: CollectionSnooper.nc,v 1.1.2.2 2006-02-14 17:01:45 idgay Exp $
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
 * Copyright (c) 2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * The OSKI presentation of overhearing a collection routing packet
 * that is sent to another node. The Intercept.intercepted() event is
 * only signaled when a node receives a routing packet whose next hop
 * is another node. The return value of the event is ignored.  If the
 * packet's next hop is the node, then either the
 * CollectionInterceptor (if it is a next hop) or CollectionReceiver
 * (if it is a tree root) will instead be used. CollectionSnooper is a
 * way for a component to overhear routed messages from other nodes if
 * it is a leaf in the network. 
 *
 * @author Philip Levis
 * @date   January 10 2005
 */ 

#include "Collection.h"

generic configuration CollectionSnooper(collect_id_t id) {
  provides {
    interface Intercept as Snoop;
    interface Packet;
  }
}

implementation {
  components CollectionImpl;

  Snoop = CollectionImpl.Intercept[id];
  Packet = CollectionImpl;
}
