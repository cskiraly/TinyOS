// $Id: SimMainP.nc,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $

/*									tab:4
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: SimMainP.nc,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $
 *
 */

/**
 * SimMainP implements the TOSSIM TinyOS boot sequence, as documented
 * in TEP 107. It differs from RealMainP (its mote counterpart) in that
 * it does not actually define a <tt>main</tt> function.
 *
 * @author Philip Levis
 * @date   August 17 2005
 */

static void __nesc_nido_initialise(int node);

module SimMainP {
  provides interface Boot;
  uses interface Scheduler;
  uses interface Init as PlatformInit;
  uses interface Init as SoftwareInit;
}
implementation {
  char timeBuf[256];
  
  int sim_main_start_mote() __attribute__ ((C, spontaneous)) {
    atomic {
      __nesc_nido_initialise(sim_node());
      /* First, initialize the Scheduler so components can post
	 tasks. Initialize all of the very hardware specific stuff, such
	 as CPU settings, counters, etc. After the hardware is ready,
	 initialize the requisite software components and start
	 execution.*/
      
      call Scheduler.init(); 
      
      /* Initialize the platform. Then spin on the Scheduler, passing
       * FALSE so it will not put the system to sleep if there are no
       * more tasks; if no tasks remain, continue on to software
       * initialization */
      call PlatformInit.init();    
      while (call Scheduler.runNextTask(FALSE));
      
      /* Initialize software components.Then spin on the Scheduler,
       * passing FALSE so it will not put the system to sleep if there
       * are no more tasks; if no tasks remain, the system has booted
       * successfully.*/
      call SoftwareInit.init(); 
      while (call Scheduler.runNextTask(FALSE));
    }
    
    /* Enable interrupts now that system is ready. */
    __nesc_enable_interrupt();

    sim_print_now(timeBuf, 256);
    printf("Mote %i signaling boot at time %s.\n", sim_node(), timeBuf);
    signal Boot.booted();
    
    /* Normally, at this point a mote enters a while(1) loop to
     * execute tasks. In TOSSIM, this call completes: posted tasks
     * are part of the global TOSSIM event loop. Look at
     * SimSchedulerBasicP for more details. */
    return 0;
  }

  default command error_t PlatformInit.init() { return SUCCESS; }
  default command error_t SoftwareInit.init() { return SUCCESS; }
  default event void Boot.booted() { }
}

