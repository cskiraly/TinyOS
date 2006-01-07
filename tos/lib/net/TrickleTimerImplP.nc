// $Id: TrickleTimerImplP.nc,v 1.1.2.1 2006-01-07 23:42:57 scipio Exp $
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
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
 */

/*
 * Module that provides a service instance of trickle timers. For
 * details on the working of the parameters, please refer to Levis et
 * al., "A Self-Regulating Algorithm for Code Maintenance and
 * Propagation in Wireless Sensor Networks," NSDI 2004.
 *
 * @param l Lower bound of the time period in seconds.
 * @param h Upper bound of the time period in seconds.
 * @param k Redundancy constant.
 * @param count How many timers to provide.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 * @date   Jan 7 2006
 */ 

#include <Timer.h>

generic module TrickleTimerImplP(uint16_t low,
				 uint16_t high,
				 uint8_t k,
				 uint8_t count) {
  provides {
    interface Init;
    interface TrickleTimer[uint8_t];
  }
  uses {
    interface Timer<TMilli>;
    interface BitVector as Pending;
    interface BitVector as Changed;
    interface Random;
  }
}
implementation {

  typedef struct {
    uint16_t period;
    uint16_t time;
    uint16_t remainder;
    uint8_t count;
  } trickle_t;

  trickle_t trickles[count];
  
  void adjustTimer();
  void generateTime(uint8_t id);
  
  command error_t Init.init() {
    int i;
    for (i = 0; i < count; i++) {
      trickles[i].period = high;
      trickles[i].count = 0;
      trickles[i].time = 0;
      trickles[i].remainder = 0;
    }
    atomic {
      call Pending.clearAll();
      call Changed.clearAll();
    }
    return SUCCESS;
  }

  /**
   * Start a trickle timer. Reset the counter to 0.
   */
  command error_t TrickleTimer.start[uint8_t id]() {
    if (trickles[id].time != 0) {
      return EBUSY;
    }
    trickles[id].time = 0;
    trickles[id].remainder = 0;
    trickles[id].count = 0;
    generateTime(id);
    atomic {
      call Changed.set(id);
    }
    adjustTimer();
    return SUCCESS;
  }

  /**
   * Stop the trickle timer. This call sets the timer period to H.
   */
  command void TrickleTimer.stop[uint8_t id]() {
    trickles[id].time = 0;
    trickles[id].period = high;
    adjustTimer();
  }

  /**
   * Reset the timer period to L. If called while the timer is running,
   * then a new interval (of length L) begins immediately.
   */
  command void TrickleTimer.reset[uint8_t id]() {
    trickles[id].period = low;
    trickles[id].count = 0;
    if (trickles[id].time != 0) {
      atomic {
	call Changed.set(id);
      }
      trickles[id].time = 0;
      generateTime(id);
      adjustTimer();
    }
  }

  /**
   * Increment the counter C. When an interval ends, C is set to 0.
   */
  command void TrickleTimer.incrementCounter[uint8_t id]() {
    trickles[id].count++;
  }

  task void timerTask() {
    uint8_t i;
    for (i = 0; i < count; i++) {
      bool fire = FALSE;
      atomic {
	if (call Pending.get(i)) {
	  call Pending.clear(i);
	}
	fire = TRUE;
      }
      if (fire) {
	signal TrickleTimer.fired[i]();
	post timerTask();
	return;
      }
    }
  }
  
  /**
   * The trickle timer has fired. Signaled if C &gt; K.
   */  
  event void Timer.fired() {
    uint8_t i;
    uint16_t dt = (uint16_t)call Timer.getdt();
    for (i = 0; i < count; i++) {
      uint16_t remaining = trickles[i].time;
      if (remaining != 0) {
	remaining -= dt;
	if (remaining == 0 && trickles[i].count < k) {
	  atomic {
	    call Pending.set(i);
	  }
	  generateTime(i);

	  /* Note that this logic is not the exact trickle algorithm.
	   * Rather than C being reset at the beginning of an interval,
	   * it is being reset at a firing point. This means that the
	   * listening period, rather than of length tau/2, is in the
	   * range [tau/2, tau]. 
	   */
	  trickles[i].count = 0;
	  post timerTask();
	}
	else {
	  trickles[i].time = remaining;
	}
      }
    }
    adjustTimer();
  }

  // This is where all of the work is done!
  void adjustTimer() {
    uint8_t i;
    uint16_t lowest = 0;
    bool set = FALSE;

    // How much time has elapsed on the current timer
    // since it was scheduled? This value is needed because
    // the time remaining of a running timer is its time
    // value minus tiem elapsed.
    uint16_t elapsed = (call Timer.getNow() - call Timer.gett0()) >> 10;
	
    for (i = 0; i < count; i++) {
      uint16_t time = trickles[i].time;
      if (time != 0) {
	atomic {
	  if (!call Changed.get(i)) {
	    call Changed.clear(i);
	    time -= elapsed;
	  }
	}
	if (!set) {
	  lowest = time;
	  set = TRUE;
	}
	else if (time < lowest) {
	  lowest = time;
	}
      }
    }
    if (set) {
      uint32_t timerVal = lowest;
      timerVal = timerVal << 10;
      call Timer.startOneShot(timerVal);
    }
    else {
      call Timer.stop();
    }
  }

  /* Generate a new firing time for a timer. if the timer was already
   * running (time != 0), then double the period.
   */
  void generateTime(uint8_t id) {
    uint16_t time;

    if (trickles[id].time != 0) {
      trickles[id].period *= 2;
      if (trickles[id].period > high) {
	trickles[id].period = high;
      }
    }
    
    trickles[id].time = trickles[id].remainder;
    
    time = trickles[id].period / 2;
    time += call Random.rand16() % (trickles[id].period / 2);

    trickles[id].remainder = trickles[id].period - time;
    trickles[id].time += time;
  }

 default event void TrickleTimer.fired[uint8_t id]() {
   return;
 }
}

  
