/// $Id: VoltageC.nc,v 1.1.2.1 2006-02-17 12:34:06 beutel Exp $

/**
 * Copyright (c) 2006 ETH Zurich.  
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
/**
 * @author Hu Siquan <husq@xbow.com>
 * @author Jan Beutel
 */
configuration VoltageC
{
  provides interface StdControl;	
  provides interface Read<uint16_t>;
}
implementation
{
  components VoltageP, new AdcReadClientC() as VoltageChannel,
    HplAtm128GeneralIOC as Pins;
  
  StdControl  = VoltageP;  
  Read = VoltageChannel;
  VoltageChannel.Atm128AdcConfig -> VoltageP;
  VoltageP.BAT_MON -> Pins.PortF3;
}
