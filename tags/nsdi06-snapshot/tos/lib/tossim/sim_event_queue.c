// $Id: sim_event_queue.c,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $

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


#include <heap.h>
#include <sim_event_queue.h>

static heap_t eventHeap;

void sim_queue_init() __attribute__ ((C, spontaneous)) {
  init_heap(&eventHeap);
}

void sim_queue_insert(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  heap_insert(&eventHeap, event, event->time);
}

sim_event_t* sim_queue_pop() __attribute__ ((C, spontaneous)) {
  long long int key;
  return (sim_event_t*)(heap_pop_min_data(&eventHeap, &key));
}

bool sim_queue_is_empty() __attribute__ ((C, spontaneous)) {
  return heap_is_empty(&eventHeap);
}

long long int sim_queue_peek_time() __attribute__ ((C, spontaneous)) {
  if (heap_is_empty(&eventHeap)) {
    return -1;
  }
  else {
    return heap_get_min_key(&eventHeap);
  }
}


void sim_queue_cleanup_none(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  // Do nothing. Useful for statically allocated events.
}

void sim_queue_cleanup_event(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  free(event);
}

void sim_queue_cleanup_data(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  free (event->data);
  event->data = NULL;
}
    
void sim_queue_cleanup_total(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  free (event->data);
  event->data = NULL;
  free (event);
}
