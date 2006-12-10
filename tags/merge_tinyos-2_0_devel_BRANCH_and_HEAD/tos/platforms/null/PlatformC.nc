// $Id: PlatformC.nc,v 1.1.2.3 2006-11-07 23:15:24 scipio Exp $
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

module PlatformC { 
  provides interface Init;
}
implementation {
  command error_t Init.init() {
    return SUCCESS;
  }
}
