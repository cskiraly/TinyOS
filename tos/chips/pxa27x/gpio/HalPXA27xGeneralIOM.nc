// $Id: HalPXA27xGeneralIOM.nc,v 1.1.2.1 2005-11-05 01:54:39 philipb Exp $

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

//@author Phil Buonadonna
module HalPXA27xGeneralIOM {
  provides {
    interface GeneralIO[uint8_t pin];
  }
  uses {
    interface HplPXA27xGPIOPin[uint8_t pin];
  }
}

implementation {
  async command void GeneralIO.set[uint8_t pin]() 
  {
    
    atomic call HplPXA27xGPIOPin.setOutput[pin]();
    return;
  }

  async command void GeneralIO.clr[uint8_t pin]() 
  {
    atomic call HplPXA27xGPIOPin.clearOutput[pin]();
    return;
  }

  async command void GeneralIO.toggle[uint8_t pin]() 
  {
    atomic {
      if (call HplPXA27xGPIOPin.getLevel[pin]()) {
	call HplPXA27xGPIOPin.clearOutput[pin]();
      }
      else {
	call HplPXA27xGPIOPin.setOutput[pin]();
      }
    }
    return;
  }

  async command bool GeneralIO.get[uint8_t pin]() 
  {
    return call HplPXA27xGPIOPin.getLevel[pin]();
  }

  async command void GeneralIO.makeInput[uint8_t pin]() 
  {
    atomic call HplPXA27xGPIOPin.setDirection[pin](FALSE);
    return;
  }

  async command void GeneralIO.makeOutput[uint8_t pin]() 
  {
    atomic call HplPXA27xGPIOPin.setDirection[pin](TRUE);
    return;
  }

  async event void HplPXA27xGPIOPin.eventEdge[uint8_t pin]() 
  {

    return;
  }
}
