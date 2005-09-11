/*									tab:4
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
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Packet-level interface to ChipCon CC2420 radio. This configuration
 * connects the platform-independent implemenation to the
 * platform-specific abstractions (such as SPI access and pins).
 * 
 * <pre>
 *   $Id: CC2420RadioC.nc,v 1.1.2.3 2005-09-11 19:31:59 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @date   August 28 2005
 */

configuration CC2420RadioC
{
  provides {
    interface Init;
    interface SplitControl;
    interface Send as Send;
    interface Receive as Receive;
    interface CC2420Control;
    interface PacketAcknowledgements as Acks;
    interface CSMABackoff;
    interface RadioTimeStamping;
  }
}
implementation
{
  components CC2420RadioP as Radio, CC2420ControlP as Control;
  components CC2420C as CC2420Platform, CC2420PlatformAlarmC;
  components HplCC2420PinsC;
  
  components RandomC, LedsC;

  Init = CC2420PlatformAlarmC;
  Init = Radio;

  SplitControl      = Radio;
  Send              = Radio;
  Receive           = Radio;
  CSMABackoff       = Radio;
  Acks              = Radio;
  RadioTimeStamping = Radio;
  CC2420Control     = Control;


  Radio.Random             -> RandomC;
  Radio.CC2420Init         -> Control;
  Radio.CC2420SplitControl -> Control;
  Radio.CC2420Control      -> Control;
  Radio.CC2420Fifo         -> CC2420Platform;
  Radio.FIFOP              -> CC2420Platform.InterruptFIFOP;
  Radio.SFD                -> CC2420Platform.CaptureSFD;
  Radio.RXFIFO             -> CC2420Platform.RXFIFO;
  Radio.SFLUSHRX           -> CC2420Platform.SFLUSHRX;
  Radio.SFLUSHTX           -> CC2420Platform.SFLUSHTX;
  Radio.SNOP               -> CC2420Platform.SNOP;
  Radio.STXONCCA           -> CC2420Platform.STXONCCA;
  Radio.BackoffTimer       -> CC2420PlatformAlarmC;
  Radio.CC_SFD             -> HplCC2420PinsC.CC_SFD;
  Radio.CC_FIFO            -> HplCC2420PinsC.CC_FIFO;
  Radio.CC_CCA             -> HplCC2420PinsC.CC_CCA;
  Radio.CC_FIFOP           -> HplCC2420PinsC.CC_FIFOP;

  Control.HPLChipconInit    -> CC2420Platform;
  Control.HPLChipconControl -> CC2420Platform;
  Control.Ram               -> CC2420Platform;
  Control.MAIN              -> CC2420Platform.MAIN;
  Control.MDMCTRL0          -> CC2420Platform.MDMCTRL0;
  Control.MDMCTRL1          -> CC2420Platform.MDMCTRL1;
  Control.RSSI              -> CC2420Platform.RSSI;
  Control.SYNCWORD          -> CC2420Platform.SYNCWORD;
  Control.TXCTRL            -> CC2420Platform.TXCTRL;
  Control.RXCTRL0           -> CC2420Platform.RXCTRL0;
  Control.RXCTRL1           -> CC2420Platform.RXCTRL1;
  Control.FSCTRL            -> CC2420Platform.FSCTRL;
  Control.SECCTRL0          -> CC2420Platform.SECCTRL0;
  Control.SECCTRL1          -> CC2420Platform.SECCTRL1;
  Control.IOCFG0            -> CC2420Platform.IOCFG0;
  Control.IOCFG1            -> CC2420Platform.IOCFG1;
  Control.SFLUSHTX          -> CC2420Platform.SFLUSHTX;
  Control.SFLUSHRX          -> CC2420Platform.SFLUSHRX;
  Control.SXOSCOFF          -> CC2420Platform.SXOSCOFF;
  Control.SXOSCON           -> CC2420Platform.SXOSCON;
  Control.SRXON             -> CC2420Platform.SRXON;
  Control.STXON             -> CC2420Platform.STXON;
  Control.STXONCCA          -> CC2420Platform.STXONCCA;
  Control.CCA               -> CC2420Platform.InterruptCCA;
  Control.CC_RSTN           -> HplCC2420PinsC.CC_RSTN;
  Control.CC_VREN           -> HplCC2420PinsC.CC_VREN;

}
