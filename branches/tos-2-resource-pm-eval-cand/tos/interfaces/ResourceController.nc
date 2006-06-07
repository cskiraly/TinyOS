/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
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
 *
 */
 
/**
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.<br><br>
 *
 * This interface is an extension of the Resource interface.  It has all of the
 * commands and events present in both the Resource interface, and the
 * ImmediateResource interface along with two additional
 * events.  These events allow the user of this interface to be notified whenever
 * someone requests the use of a resource or whenever the resource becomes idle.
 * One could use this interface to control access to a resource by always
 * taking control of a resource whenever it has gone idle and deciding when to
 * release it based on requests from other users.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.3.2.2 $
 * @date $Date: 2006-06-07 10:47:17 $ 
 */

interface ResourceController {
  /**
  * Request immediate access to the shared resource. You must call
  * release() when you are done with it.
  *
  * @return SUCCESS You now have control of the resource.<br>
  *            EBUSY The resource is busy.  You must try again later
  */
  async command error_t request();

  /**
  * Release a shared resource you previously acquired in synchronous context.
  *
  * @return SUCCESS The resource has been released and pending requests
  *                           can resume. <br>
  *             FAIL You tried to release but you are not the
  *                    owner of the resource
  */
  command error_t release();

  /**
  * Release a shared resource you previously acquired in asynchronous context.
  *
  * @return SUCCESS The resource has been released and a user currently
  *                           making an immediateRequest can be granted access
  *                           to the Resource. <br>
  *             FAIL You tried to release but you are not the
  *                    owner of the resource.
  */
  async command error_t immediateRelease();

  /**
  * You are now in control of the resource. Note that this event
  * is NOT signaled when immediateRequest() succeeds.
  */
  event void granted();

  /**
   *  Check if the user of this interface is the current
   *  owner of the Resource
   *  @return TRUE  It is the owner <br>
   *          FALSE It is not the owner
   */
  async command bool isOwner();

  /**
   * This event is signalled whenever the user of this interface
   * currently has control of the resource, and another user requests
   * it through the use of the normal Resource interface.
   * You may want to consider releasing a resource based on this
   * event
   */
  event void requested();

  /**
  * This event is signalled whenever the user of this interface
  * currently has control of the resource, and another user requests
  * it through the use of the ImmediateResource interface.
  * You may want to consider releasing a resource based on this
  * event
  */
  async event void immediateRequested();

  /**
   * Event sent to the resource controller whenever a resource goes idle.
   * That is to say, whenever no one currently owns the resource, and there
   * are no more pending requests
   */
  async event void idle();
}
