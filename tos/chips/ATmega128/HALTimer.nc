/// $Id: HALTimer.nc,v 1.1.2.3 2005-03-15 01:32:20 mturon Exp $

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

includes HPLTimer;

interface HPLTimer<size_type>
{
  /// Timer value register: Direct access
  async command size_type get();
  async command void      set(size_type t);

  /// Interrupt signals
  async event void overflow();        //<! Signalled on overflow interrupt

  /// Interrupt flag utilites: Bit level set/clr
  async command void resetOverflow(); //<! Clear the overflow interrupt flag
  async command void startOverflow(); //<! Enable the overflow interrupt
  async command void stopOverflow();  //<! Turn off overflow interrupts
  async command bool testOverflow();  //<! Did overflow interrupt occur?
  async command bool checkOverflow(); //<! Is overflow interrupt on?
}
