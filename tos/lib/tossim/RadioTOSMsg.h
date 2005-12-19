// $Id: RadioTOSMsg.h,v 1.1.2.1 2005-12-19 23:51:20 scipio Exp $
/*
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
 *
 */
 
/**
 * Defining the platform-independently named packet structures to be the
 * tossim structures.
 *
 * @author Philip Levis
 * @date   Dec 2 2005
 * Revision:  $Revision: 1.1.2.1 $
 */


#ifndef RADIO_TOS_MSG_H
#define RADIO_TOS_MSG_H

#include <TossimRadioMsg.h>
#include <Serial.h>

typedef union TOSRadioHeader {
  tossim_header_t tossim;
  SerialAMHeader serial;
} TOSRadioHeader;

typedef union TOSRadioFooter {
  tossim_footer_t tossim;
} TOSRadioFooter;

typedef union TOSRadioMetadata {
  tossim_metadata_t tossim;
} TOSRadioMetadata;

#endif
