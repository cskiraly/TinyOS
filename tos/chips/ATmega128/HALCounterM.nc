/// $Id: HALCounterM.nc,v 1.1.2.1 2005-02-09 17:52:35 mturon Exp $

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

/** 
 * The HALCounterM provides Counter services described in TEP 102.  
 * This implementation uses nesC 1.2 generics to automatically convert
 * overflow events from a hardware timer of arbitrary bit width into a
 * larger resolution count of time.  The technique shown here should 
 * be added to TEP 102.
 */
module HALCounterM
{
    provides interface Counter<counter_size, frequency_tag> as Counter;

    uses interface HALTimer<timer_size> as Timer;
}

implementation
{
    union time_u
    {
	timer_size   low;
	counter_size full;
    };
    
    norace time_u lastCount;	// cache the counter high bits
    
    async command counter_size HALCounter.get()
    {
	union time_u time;
	time.full = lastCount.full;
	time.low  = call Timer.get();
	
	/*
	 * Adjust time if we did not handle the overflow interrupt yet
	 * AND time.low already shows this fact.
	 */
	if( call Timer.testOverflow() && (timer_size)time.low >= 0 ) {
	    time.low = (timer_size)-1;  // max out low bits
	    ++time.full;                // increment timer
	}
	
	return time.full;
    }
    
    async event void Timer.overflow()
    {
	/** Maximize low bits, increment counter, and signal overflow. */
	lastCount.low = -1;
	if( ++lastCount.full == 0 )
	    signal HALCounter.overflow();
    }
    
    async command bool HALCounter.isOverflowPending()
    {
	/* Check if high bits are maximized and interrupt pending. */
	return ((lastCount.full | (timer_size)-1) == (counter_size)-1
		&& call Timer.testOverflow());
    }

    async command bool HALCounter.clearOverflow()
    {
	call Timer.resetOverflow();
    }
}
