/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2005-04-25 18:40:49 $ 
 * ======================================================================== 
 */
 
 /**
 * Resource interface.  
 * This interface is to be used by components for providing access to 
 * shared resources.  A component wishing to arbitrate the use of a shared 
 * resource should implement this interface in conjunction with the 
 * ResourceUser interface.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

interface Resource {
  /**
   * Request access to a shared resource. You must call release()
   * when you are done with it.
   * @return SUCCESS You have gained access to the resource.
   *         EBUSY   The resource is busy. The current owner of 
   *                 the bus will receive the requested() event
   *         FAIL    The resource could not be allocated.  There
   *                 is no current owner, but for some reason
   *                 the resource could not be given to you.
   */
  async command error_t request();
  
  /**
   * Some other component has requested this resource. You might
   * want to consider releasing it.
   */
  event void requested();  

  /**
   * You have received access to this resource.
   */
  event void granted();

  /**
   * Release a shared resource you previously acquired.
   */
  async command void release();
  
  /**
   * Notification of a shared resource being released
   */
  event void released();  
}
