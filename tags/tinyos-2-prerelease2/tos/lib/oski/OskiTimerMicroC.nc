/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University of California.  
 *  Copyright (c) 2005 Stanford University. 
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
 *  @author Martin Turon <mturon@xbow.com>
 *  @author Philip Levis
 *
 *  $Id: OskiTimerMicroC.nc,v 1.1.2.1 2005-10-10 02:59:48 mturon Exp $
 */

/**
 * The OSKI presentation of a timer with microsecond granularity.
 *
 * @author Martin Turon
 * @author Philip Levis
 * @date   October 10 2005
 */ 

includes Timer;

generic configuration OskiTimerMicroC() {
  provides interface Timer<TMicro>;
}
implementation {
  components TimerMicroImplP;

  // The key to unique is based off of TimerMicroC because TimerMicroImplP
  // is just a pass-through to the underlying HIL component (TimerMicro).
  Timer = TimerMicroImplP.TimerMicro[unique("TimerMicroC.TimerMicro")];
}

