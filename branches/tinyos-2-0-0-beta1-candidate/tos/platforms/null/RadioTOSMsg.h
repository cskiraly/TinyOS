// $Id: RadioTOSMsg.h,v 1.1.2.2 2006-01-27 20:24:16 idgay Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Dummy implementation to support the null platform.
 */

#ifndef RADIO_TOS_MSG_H
#define RADIO_TOS_MSG_H

typedef nx_struct {
  nx_int8_t dummy;
} TOSRadioHeader;

typedef nx_struct {
  nx_int8_t dummy;
} TOSRadioFooter;

typedef nx_struct {
  nx_int8_t dummy;
} TOSRadioMetadata;

#endif
