// $Id: Service.nc,v 1.1.2.1 2005-05-17 21:25:23 scipio Exp $
/*									tab:4
 * "Copyright (c) 2004-5 The Regents of the University  of California.  
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
 * Copyright (c) 2004-5 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
  * Control and query whether an instance of a given service is active
  * or not. The semantics of the <tt>start</tt> and <tt>stop</tt>
  * commands are implementation dependent, but the common semantics
  * (and the case unless a component says otherwise) are a binary-OR
  * model. That is, a service is running if any of its instances is
  * active (started), and only not running if all of its instances are
  * stopped.
  *
  * <p>This means that a component can call <tt>stop()</tt>, yet have
  * <tt>isRunning()</tt> return true, because someone else has kept
  * the service active. Note, however, that if this component tries
  * using the service without calling <tt>start()</tt>, it might
  * suddenly fail if the other instance calls <tt>stop()</tt>: the
  * service may think no one is using it so it can safely stop. The
  * <tt>started()</tt> command returns whether the particular instance
  * is active, while <tt>isRunning</tt> returns whether the service as
  * a whole is active.
  *
  * @author Philip Levis
  * @date   January 5 2005
  */ 


interface Service {

  /**
   *
   */
  command void start();

  command void stop();

  command bool isRunning();

  
}
