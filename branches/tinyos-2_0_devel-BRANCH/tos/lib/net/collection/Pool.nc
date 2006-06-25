/* $Id: Pool.nc,v 1.1.2.5 2006-06-25 18:58:48 scipio Exp $ */
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

/**
 *  An allocation pool of a specific type memory objects.
 *  The Pool allows components to allocate (<code>get</code>)
 *  and deallocate (<code>put</code>) elements.
 *
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-06-25 18:58:48 $
 */

   
interface Pool<t> {

  /**
    * Returns whether there any elements remaining in the pool.
    * If empty returns TRUE, then <code>get</code> will return
    * NULL. If empty returns FALSE, then <code>get</code> will
    * return a pointer to an object.
    *
    * @return Whether the pool is empty.
    */

  command bool empty();

  /**
    * Returns how many elements are in the pool. If size
    * returns 0, empty() will return TRUE. If size returns
    * a non-zero value, empty() will return FALSE. The
    * return value of size is always &lte; the return
    * value of maxSize().
    *
    * @return How many elements are in the pool.
    */
  command uint8_t size();
  
  /**
    * Returns the maximum number of elements in the pool
    * (the size of a full pool).
    *
    * @return Maximum size.
    */
  command uint8_t maxSize();

  /**
    * Deallocate an object, putting it back into the pool.
    *
    * @return SUCCESS if the entry was put in successfully, FAIL
    * if the pool is full.
    */
  command error_t put(t* newVal);

  /**
    * Allocate an element from the pool.
    *
    * @return A pointer if the pool is not empty, NULL if
    * the pool is empty.
    */
  command t* get();
}
