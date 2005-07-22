/// $Id: PlatformM.nc,v 1.1.2.7 2005-07-22 08:33:32 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

includes hardware;

module PlatformM
{
  provides interface Init;
  uses interface Init as MoteInit;
}
implementation
{
  void power_init() {
      atomic {
	MCUCR = _BV(SE);      // Internal RAM, IDLE, rupt vector at 0x0002,
			      // enable sleep instruction!
      }
  }

  command error_t Init.init()
  {
    error_t ok = call MoteInit.init();

    if (ok != SUCCESS)
      return ok;

    power_init();

    return SUCCESS;
  }
}

