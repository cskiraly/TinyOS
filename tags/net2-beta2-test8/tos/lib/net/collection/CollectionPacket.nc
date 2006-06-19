/* $Id: CollectionPacket.nc,v 1.1.2.2 2006-06-19 21:22:04 scipio Exp $ */
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
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
 */

/*
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-06-19 21:22:04 $
 */

#include <AM.h>
   
interface CollectionPacket {
  command am_addr_t getOrigin(message_t* msg);
  command void setOrigin(message_t* msg, am_addr_t addr);

  command uint8_t getCollectionID(message_t* msg);
  command void setCollectionID(message_t* msg, uint8_t id);

  command uint8_t getControl(message_t* msg);
  command void setControl(message_t* msg, uint8_t control);

  command uint8_t getGradient(message_t* msg);
  command void setGradient(message_t* msg, uint8_t control);
}
