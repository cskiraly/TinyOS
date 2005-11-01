/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Alan Broad, Crossbow <abroad@xbow.com>
 *  @author Matt Miller, Crossbow <mmiller@xbow.com>
 *  @author Martin Turon, Crossbow <mturon@xbow.com>
 *
 *  $Id: Atm128CaptureC.nc,v 1.1.2.1 2005-10-27 20:31:27 idgay Exp $
 */

/**
 * Exposes Capture capability of hardware as general interface, 
 * with some ATmega128 specific dependencies including:
 *     Only available with the two 16-bit timers.
 *     Each Timer has only one dedicated capture pin.
 *         Timer1 == PortD.Pin4 [D4]
 *         Timer3 == PortE.Pin7 [E7]
 * So selection of 16-bit timer gives implicit wiring of actual Pin to capture.
 *
 * @version    mturon     2005/7/30      Intial revision.
 */
generic module Atm128CaptureP () 
{
  provides {
    interface Capture as CapturePin;
  }
  uses {
    interface HplCapture<uint16_t>;
    // interface HplTimer<uint16_t> as Timer;
    // interface GeneralIO as PinToCapture;       // implicit to timer used
  }
}
implementation
{
  // ************* CapturePin Interrupt handlers and dispatch *************

  /**
   *  CapturePin.enableCapture
   *
   * Configure Atmega128 TIMER to capture edge input of CapturePin signal.
   * This will cause an interrupt and save TIMER count.
   * TIMER Timebase is set by stdControl.start
   *  -- see HplCapture interface and HplTimerM implementation
   */
  async command error_t CapturePin.enableCapture(bool low_to_high) {
    atomic {
      call HplCapture.stop();  // clear any capture interrupt
      call HplCapture.setEdge(low_to_high);
      call HplCapture.reset();
      call HplCapture.start();
    }
    return SUCCESS;
  }
    
  async command error_t CapturePin.disable() {
    call HplCapture.stop();
    return SUCCESS;
  }
    
  /**
   * Handle signal from HplCapture interface indicating an external 
   * event has been timestamped. 
   * Signal client with time and disable capture timer if nolonger needed.
   */
  async event void HplCapture.captured(uint16_t time) {
    // first, signal client
    error_t val = signal CapturePin.captured(time);     

    if (val == FAIL) {
      // if client returns failure, stop time capture
      call HplCapture.stop();
    } else { 
      // otherwise, time capture keeps running, reset if needed
      if (call HplCapture.test()) 
	call HplCapture.reset();
    }         
  }
}
