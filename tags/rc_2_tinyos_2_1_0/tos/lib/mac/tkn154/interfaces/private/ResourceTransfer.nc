/* 
 * Copyright (c) 2008, Technische Universitaet Berlin All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.  - Redistributions in
 * binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.  - Neither the name of the
 * Technische Universitaet Berlin nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:00:34 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

interface ResourceTransfer
{

  /** 
   * Transfer control of a resource to another client. Conceptually, this
   * command is similar to calling Resource.release() and then forcing the
   * arbiter to signal the Resource.granted() event to the target client. But
   * there is one difference: when a resource that was transferred through this
   * command is released, it is released on behalf of the "original" client,
   * i.e. who was last signalled the Resource.granted() event.  Releasing a
   * transferred resource is thus equivalent to first transferring it back to
   * the original client and then forcing the latter to release the resource
   * through a call to Resource.release() -- this ensures that the arbitration
   * policy can continue properly (and avoids possible starvation).
   *
   * Note that a resource may be transferred multiple times, before it is
   * released. Then the current owner will change, but the "original" client
   * will stay the same.
   *
   * @return SUCCESS If ownership has been transferred.<br> FAIL ownership has
   * not been transferred, because the caller is not owner of the resource
   */

  async command error_t transfer();
}
