// $Id: RealMain.nc,v 1.1.2.1 2005-01-17 19:57:22 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
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
 * Date last modified:  $Id: RealMain.nc,v 1.1.2.1 2005-01-17 19:57:22 scipio Exp $
 *
 */

/**
 * 
 * @author Philip Levis
 * @date   January 17 2005
 */


module RealMain {
  provides interface Booted;
  uses {
    interface Scheduler;
    interface Initialize as PlatformInit;
    interface Initialize as SoftwareInit;
    interface HWSleep;
  }
}
implementation
{

  task void bootedTask() {
    signal Booted.booted();
  }

  int main() __attribute__ ((C, spontaneous)) {

    /* Initialize all of the very hardware specific stuff, such as CPU
    settings, counters, etc. Once the CPU and basic peripherals are in
    the right states -- these calls cannot post any tasks --
    initialize the Scheduler. After the Scheduler is ready, initialize
    the requisite software components and start execution.*/

    /* Enable interrupts, in case initialization calls, such as for
       oscillator calibration, require them. */
    __nesc_enable_interrupt();    

    call PlatformInit.init();  // Replaces TOSH_hardware_init in tos-1.x
    call Scheduler.init(); 
    call SoftwareInit.init(); 
    


    /* One question here is whether main should signal this event directly,
       or post a task. Currently, Main posts a task in case SoftwareInit
       causes tasks to be posted; this way, the system isn't booted until
       those tasks clear.*/
    post bootedTask();

    while (1) {
      while (call Scheduler.runTask()) {}
      call HWSleep.sleepUntilInterrupt();
    }
  }

}
