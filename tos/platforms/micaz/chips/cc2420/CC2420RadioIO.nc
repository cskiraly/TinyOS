/// $Id: CC2420RadioIO.nc,v 1.1.2.1 2005-07-06 16:11:59 mturon Exp $

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

configuration CC2420RadioIO
{
  provides {
      interface GeneralIO as CC2420RadioCS;
      interface GeneralIO as CC2420RadioFIFO;
      interface GeneralIO as CC2420RadioFIFOP;
      interface GeneralIO as CC2420RadioSFD;
      interface GeneralIO as CC2420RadioCCA;
      interface GeneralIO as CC2420RadioVREF;
      interface GeneralIO as CC2420RadioReset;
      interface GeneralIO as CC2420RadioGIO0;
      interface GeneralIO as CC2420RadioGIO1;
  }
}
implementation
{
  components HPLGeneralIO;

  CC2420RadioVREF = HPLGeneralIO.PortA5;
  CC2420RadioReset = HPLGeneralIO.PortA6;

  CC2420RadioCS = HPLGeneralIO.PortB0;
  CC2420RadioFIFO = HPLGeneralIO.PortB7;
  CC2420RadioFIFOP = HPLGeneralIO.PortD7;
  CC2420RadioSFD = HPLGeneralIO.PortD4;
  CC2420RadioCCA = HPLGeneralIO.PortD6;

  CC2420RadioGIO0 = HPLGeneralIO.PortB7;   // same as FIFO?
  CC2420RadioGIO1 = HPLGeneralIO.PortD6;   // same as CCA?
}

