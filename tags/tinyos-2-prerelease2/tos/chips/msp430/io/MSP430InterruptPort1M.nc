//$Id: MSP430InterruptPort1M.nc,v 1.1.2.2 2005-04-22 19:19:06 jpolastre Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
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

/**
 * @author Joe Polastre
 */
module MSP430InterruptPort1M
{
#ifdef __msp430_have_port1
  provides interface MSP430Interrupt as Port10;
  provides interface MSP430Interrupt as Port11;
  provides interface MSP430Interrupt as Port12;
  provides interface MSP430Interrupt as Port13;
  provides interface MSP430Interrupt as Port14;
  provides interface MSP430Interrupt as Port15;
  provides interface MSP430Interrupt as Port16;
  provides interface MSP430Interrupt as Port17;
#endif

}
implementation
{

#ifdef __msp430_have_port1
  TOSH_SIGNAL(PORT1_VECTOR)
  {
    volatile int n = P1IFG & P1IE;

    if (n & (1 << 0)) { signal Port10.fired(); return; }
    if (n & (1 << 1)) { signal Port11.fired(); return; }
    if (n & (1 << 2)) { signal Port12.fired(); return; }
    if (n & (1 << 3)) { signal Port13.fired(); return; }
    if (n & (1 << 4)) { signal Port14.fired(); return; }
    if (n & (1 << 5)) { signal Port15.fired(); return; }
    if (n & (1 << 6)) { signal Port16.fired(); return; }
    if (n & (1 << 7)) { signal Port17.fired(); return; }
  }

  default async event void Port10.fired() { call Port10.clear(); }
  default async event void Port11.fired() { call Port11.clear(); }
  default async event void Port12.fired() { call Port12.clear(); }
  default async event void Port13.fired() { call Port13.clear(); }
  default async event void Port14.fired() { call Port14.clear(); }
  default async event void Port15.fired() { call Port15.clear(); }
  default async event void Port16.fired() { call Port16.clear(); }
  default async event void Port17.fired() { call Port17.clear(); }
  async command void Port10.enable() { P1IE |= (1 << 0); }
  async command void Port11.enable() { P1IE |= (1 << 1); }
  async command void Port12.enable() { P1IE |= (1 << 2); }
  async command void Port13.enable() { P1IE |= (1 << 3); }
  async command void Port14.enable() { P1IE |= (1 << 4); }
  async command void Port15.enable() { P1IE |= (1 << 5); }
  async command void Port16.enable() { P1IE |= (1 << 6); }
  async command void Port17.enable() { P1IE |= (1 << 7); }
  async command void Port10.disable() { P1IE &= ~(1 << 0); }
  async command void Port11.disable() { P1IE &= ~(1 << 1); }
  async command void Port12.disable() { P1IE &= ~(1 << 2); }
  async command void Port13.disable() { P1IE &= ~(1 << 3); }
  async command void Port14.disable() { P1IE &= ~(1 << 4); }
  async command void Port15.disable() { P1IE &= ~(1 << 5); }
  async command void Port16.disable() { P1IE &= ~(1 << 6); }
  async command void Port17.disable() { P1IE &= ~(1 << 7); }
  async command void Port10.clear() { P1IFG &= ~(1 << 0); }
  async command void Port11.clear() { P1IFG &= ~(1 << 1); }
  async command void Port12.clear() { P1IFG &= ~(1 << 2); }
  async command void Port13.clear() { P1IFG &= ~(1 << 3); }
  async command void Port14.clear() { P1IFG &= ~(1 << 4); }
  async command void Port15.clear() { P1IFG &= ~(1 << 5); }
  async command void Port16.clear() { P1IFG &= ~(1 << 6); }
  async command void Port17.clear() { P1IFG &= ~(1 << 7); }
  async command bool Port10.getValue() { bool b; atomic b=(P1IN >> 0) & 1; return b; }
  async command bool Port11.getValue() { bool b; atomic b=(P1IN >> 1) & 1; return b; }
  async command bool Port12.getValue() { bool b; atomic b=(P1IN >> 2) & 1; return b; }
  async command bool Port13.getValue() { bool b; atomic b=(P1IN >> 3) & 1; return b; }
  async command bool Port14.getValue() { bool b; atomic b=(P1IN >> 4) & 1; return b; }
  async command bool Port15.getValue() { bool b; atomic b=(P1IN >> 5) & 1; return b; }
  async command bool Port16.getValue() { bool b; atomic b=(P1IN >> 6) & 1; return b; }
  async command bool Port17.getValue() { bool b; atomic b=(P1IN >> 7) & 1; return b; }
  async command void Port10.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 0); 
      else      P1IES |=  (1 << 0);
    }
  }
  async command void Port11.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 1); 
      else      P1IES |=  (1 << 1);
    }
  }
  async command void Port12.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 2); 
      else      P1IES |=  (1 << 2);
    }
  }
  async command void Port13.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 3); 
      else      P1IES |=  (1 << 3);
    }
  }
  async command void Port14.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 4); 
      else      P1IES |=  (1 << 4);
    }
  }
  async command void Port15.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 5); 
      else      P1IES |=  (1 << 5);
    }
  }
  async command void Port16.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 6); 
      else      P1IES |=  (1 << 6);
    }
  }
  async command void Port17.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 7); 
      else      P1IES |=  (1 << 7);
    }
  }
#endif

}
