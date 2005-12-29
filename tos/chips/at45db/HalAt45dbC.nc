// $Id: HALAT45DBC.nc,v 1.1 2005/01/22 00:26:31 idgay Exp 
/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author David Gay
 */

configuration HALAT45DBC
{
  provides {
    interface StdControl;
    interface HALAT45DB;
  }
}
implementation
{
  components HALAT45DBM, HPLAT45DBC;

  StdControl = HALAT45DBM;
  StdControl = HPLAT45DBC;
  HALAT45DBM = HALAT45DBM;

  HALAT45DBM.HPLAT45DB -> HPLAT45DBC;
}
