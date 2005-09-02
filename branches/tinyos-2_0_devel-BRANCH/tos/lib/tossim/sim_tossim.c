
// $Id: sim_tossim.c,v 1.1.2.1 2005-09-02 01:52:22 scipio Exp $

/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * The top-level TOSSIM functionality.
 *
 * @author Phil Levis
 * @date   August 19 2005
 */


#include <sim_tossim.h>
#include <sim_event_queue.h>
#include <sim_mote.h>
#include <stdlib.h>

static long long int time;
static unsigned long current_node;

void sim_init() __attribute__ ((C, spontaneous)) {
  sim_queue_init();  
}

void sim_end() __attribute__ ((C, spontaneous)) {
  sim_queue_init();
}


long long int sim_time() __attribute__ ((C, spontaneous)) {
  return time;
}
void sim_set_time(long long int t) __attribute__ ((C, spontaneous)) {
  time = t;
}

unsigned long sim_node() __attribute__ ((C, spontaneous)) {
  return current_node;
}
void sim_set_node(unsigned long node) __attribute__ ((C, spontaneous)) {
  current_node = node;
}

bool sim_run_next_event() __attribute__ ((C, spontaneous)) {
  bool result = FALSE;
  if (!sim_queue_is_empty()) {
    sim_event_t* event = sim_queue_pop();
    sim_set_time(event->time);
    sim_set_node(event->mote);
    
    if (sim_mote_is_on(event->mote) || event->force) {
      result = TRUE;
      event->handle(event);
    }
    
    event->cleanup(event);
  }

  return result;
}

int sim_print_time(char* buf, int len, long long int ftime) __attribute__ ((C, spontaneous)) {
  int hours;
  int minutes;
  int seconds;
  int secondBillionths;

  secondBillionths = (int)(ftime % (long long) 4000000);
  seconds = (int)(ftime / (long long) 4000000);
  minutes = seconds / 60;
  hours = minutes / 60;
  secondBillionths *= (long long) 25;
  seconds %= 60;
  minutes %= 60;

  return snprintf(buf, len, "%i:%i:%i.%08i", hours, minutes, seconds, secondBillionths);
}

int sim_print_now(char* buf, int len) __attribute__ ((C, spontaneous)) {
  return sim_print_time(buf, len, sim_time());
}
