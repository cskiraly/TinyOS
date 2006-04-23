/* $Id: PoolP.nc,v 1.1.2.1 2006-04-23 20:27:10 scipio Exp $ */
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
 *  @author Philip Levis
 *  @date   $Date: 2006-04-23 20:27:10 $
 */

generic module PoolP(typedef pool_t, uint8_t size) {
  provides interface Init;
  provides interface Pool<pool_t>;
}
implementation {

  uint8_t free;
  uint8_t index;
  pool_t* queue[size];
  pool_t pool[size];

  command error_t Init.init() {
    int i;
    for (i = 0; i < size; i++) {
      queue[i] = &pool[i];
    }
    free = size;
    index = 0;
  }
  
  command bool Pool.empty() {
    return free == 0;
  }
  command uint8_t Pool.size() {
    return free;
  }
    
  command uint8_t Pool.maxSize() {
    return size;
  }

  command t* Pool.pop() {
    if (free == 0) {
      return NULL;
    }
    else {
      t* rval = queue[index];
      queue[index] = NULL;
      free--;
      index = (index + 1) % size;
    }
  }
  command error_t Pool.push(t* newVal) {
    if (free >= size) {
      return FAIL;
    }
    else {
      uint8_t emptyIndex = (index + free) % size;
      queue[emptyIndex] = newVal;
      free++;
      return SUCCESS;
    }
  }
}
