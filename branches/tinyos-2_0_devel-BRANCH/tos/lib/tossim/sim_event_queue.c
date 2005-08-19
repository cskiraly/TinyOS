// $Id: sim_event_queue.c,v 1.1.2.1 2005-08-19 01:06:58 scipio Exp $

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
/**
 * The simple TOSSIM wrapper around the underlying heap.
 *
 * @author Phil Levis
 * @date   August 19 2005
 *
 */


#include <heap_array.h>
#include <sim_event_queue.h>

static heap_t heap;

void sim_queue_init() {
  init_heap(&heap);
}

void sim_queue_insert(sim_event_t* event) {
  heap_insert(&heap, event, event->time);
}

sim_event_t* sim_queue_pop() {
  long long key;
  return (sim_event_t*)(heap_pop_min_data(&heap, &key));
}

bool sim_queue_is_empty() {
  return heap_is_empty(&heap);
}

long long sim_queue_peek_time() {
  if (heap_is_empty(&heap)) {
    return -1;
  }
  else {
    return heap_get_min_key(&heap);
  }
}


void sim_queue_cleanup_none(sim_event_t* event) {
  // Do nothing. Useful for statically allocated events.
}

void sim_queue_cleanup_event(sim_event_t* event) {
  free(event);
}

void sim_queue_cleanup_data(sim_event_t* event) {
  free(event->data);
  event->data = NULL;
}
    
void sim_queue_cleanup_total(sim_event_t* event) {
  free(event->data);
  event->data = NULL;
  free(event);
}
