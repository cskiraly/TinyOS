//$Id: MSP430TimerCCC.nc,v 1.1.2.1 2005-02-08 23:00:03 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

includes MSP430Timer;

generic configuration MSP430TimerCCC(uint16_t TxCCTLx_addr, uint16_t TxCCRx_addr)
{
  provides interface MSP430TimerControl as Control;
  provides interface MSP430Compare as Compare;
  provides interface MSP430Capture as Capture;
  uses interface MSP430Timer as Timer;
}
implementation
{
  components new MSP430TimerCCM(TxCCTLx_addr,TxCCRx_addr) as TimerCC
           ;

  Control = TimerCC.Control;
  Compare = TimerCC.Compare;
  Capture = TimerCC.Capture;
  TimerCC.Timer = Timer;
}

