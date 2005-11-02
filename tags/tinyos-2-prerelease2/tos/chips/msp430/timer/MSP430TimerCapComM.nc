//$Id: MSP430TimerCapComM.nc,v 1.1.2.1 2005-03-30 17:58:27 cssharp Exp $

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

generic module MSP430TimerCapComM(
    uint16_t TxCCTLx_addr,
    uint16_t TxCCRx_addr
  )
{
  provides interface MSP430TimerControl as Control;
  provides interface MSP430Compare as Compare;
  provides interface MSP430Capture as Capture;
  uses interface MSP430Timer as Timer;
  uses interface MSP430TimerEvent as Event;
}
implementation
{
  #define TxCCTLx (*(volatile TYPE_TACCTL0*)TxCCTLx_addr)
  #define TxCCRx (*(volatile TYPE_TACCR0*)TxCCRx_addr)
  
  typedef MSP430CompareControl_t CC_t;

  DEFINE_UNION_CAST(CC2int,uint16_t,CC_t)
  DEFINE_UNION_CAST(int2CC,CC_t,uint16_t)

  uint16_t compareControl()
  {
    CC_t x = {
      cm : 1,    // capture on rising edge
      ccis : 0,  // capture/compare input select
      clld : 0,  // TBCL1 loads on write to TBCCR1
      cap : 0,   // compare mode
      ccie : 0,  // capture compare interrupt enable 
    };
    return CC2int(x);
  }

  uint16_t captureControl(uint8_t l_cm)
  {
    CC_t x = {
      cm : l_cm & 0x03,    // capture on rising edge
      ccis : 0,  // capture/compare input select
      clld : 0,  // TBCL1 loads on write to TBCCR1
      cap : 1,   // compare mode
      scs : 1,   // synchronous capture mode
      ccie : 0,  // capture compare interrupt enable 
    };
    return CC2int(x);
  }
  
  async command CC_t Control.getControl()
  {
    return int2CC(TxCCTLx);
  }

  async command bool Control.isInterruptPending()
  {
    return TxCCTLx & CCIFG;
  }

  async command void Control.clearPendingInterrupt()
  {
    CLR_FLAG(TxCCTLx,CCIFG);
  }

  async command void Control.setControl( CC_t x )
  {
    TxCCTLx = CC2int(x);
  }

  async command void Control.setControlAsCompare()
  {
    TxCCTLx = compareControl();
  }

  async command void Control.setControlAsCapture( uint8_t cm )
  {
    TxCCTLx = captureControl( cm );
  }

  async command void Capture.setEdge(uint8_t cm)
  {
    CC_t t = call Control.getControl();
    t.cm = cm & 0x03;
    TxCCTLx = CC2int(t);
  }

  async command void Capture.setSynchronous( bool sync )
  {
    if( sync )
      SET_FLAG( TxCCTLx, SCS );
    else
      CLR_FLAG( TxCCTLx, SCS );
  }

  async command void Control.enableEvents()
  {
    SET_FLAG( TxCCTLx, CCIE );
  }

  async command void Control.disableEvents()
  {
    CLR_FLAG( TxCCTLx, CCIE );
  }

  async command bool Control.areEventsEnabled()
  {
    return READ_FLAG( TxCCTLx, CCIE );
  }

  async command uint16_t Compare.getEvent()
  {
    return TxCCRx;
  }

  async command uint16_t Capture.getEvent()
  {
    return TxCCRx;
  }

  async command void Compare.setEvent( uint16_t x )
  {
    TxCCRx = x;
  }

  async command void Compare.setEventFromPrev( uint16_t x )
  {
    TxCCRx += x;
  }

  async command void Compare.setEventFromNow( uint16_t x )
  {
    TxCCRx = call Timer.get() + x;
  }

  async command bool Capture.isOverflowPending()
  {
    return READ_FLAG( TxCCTLx, COV );
  }

  async command void Capture.clearOverflow()
  {
    CLR_FLAG( TxCCTLx, COV );
  }

  async event void Event.fired()
  {
    if( (call Control.getControl()).cap ) 
      signal Capture.captured( call Capture.getEvent() );
    else
      signal Compare.fired();
  }

  default async event void Capture.captured( uint16_t n )
  {
  }

  default async event void Compare.fired()
  {
  }

  async event void Timer.overflow()
  {
  }
}

