
// $Id: tossim.c,v 1.1.2.1 2005-08-19 01:06:58 scipio Exp $

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


#include <tossim.h>
#include <sim_event_queue.h>
#include <sim_mote.h>

static long long time;
static int current_node;

void sim_init() {
  sim_queue_init();
}

long long sim_time() {
  return time;
}
void sim_set_time(long long t) {
  time = t;
}

int sim_node() {
  return current_node;
}
void sim_set_node(int node) {
  current_node = node;
}

bool sim_run_next_event() {
  sim_event_t* event = sim_queue_pop();
  sim_set_time(event->time);
  sim_set_node(event->mote);

  if (sim_mote_is_on(event->mote) || event->force) {
    event->handle(event);
  }

  event->cleanup();
}

#endif // TOSSIM_H_INCLUDED
