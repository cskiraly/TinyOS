/*
* Copyright (c) 2006, Technische Universitat Berlin
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
*/


module HplAt45dbP {
  provides {
    interface HplAt45dbByte;
  }
  uses {
		interface SpiByte as FlashSpi;
    interface GeneralIO as Select;
  }
}
implementation
{
  command void HplAt45dbByte.select() {
    call Select.clr();
  }

  command void HplAt45dbByte.deselect() {
    call Select.set();
  }
  
	task void idleTask() {
		uint8_t status;
		call FlashSpi.write( 0, &status );
		if (!(status & 0x80)) {
			post idleTask();
		} else {
			signal HplAt45dbByte.idle();
		}
	}

  command void HplAt45dbByte.waitIdle() {
		post idleTask();
  }
  
  command bool HplAt45dbByte.getCompareStatus() {
		uint8_t status;
		call FlashSpi.write( 0, &status );
    return (!(status & 0x40));
  }
}
