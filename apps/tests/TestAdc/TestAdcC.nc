/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.5 $
 * $Date: 2006-01-27 23:13:21 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Tests the AdcC and switches on LED1, LED2 and LED3 if the test is successful:
 * LED1 denotes a successful Read operation,
 * LED2 denotes a successful ReadNow operation,
 * LED3 denotes a successful ReadStream operation.
 *
 * Author: Jan Hauer
 * Date: January 13 (a Friday), 2005
 **/
module TestAdcC
{
  uses interface Read<uint16_t> as Read;
  //uses interface ReadNow<uint16_t> as ReadNow;
  uses interface ReadStream<uint16_t> as ReadStream;
  uses interface Boot;
  uses interface Leds;
}
implementation
{
#define BUF_SIZE 100
  uint16_t buf[BUF_SIZE];
  
  event void Boot.booted()
  {
    //call ReadNow.read();
    call Read.read();
    call ReadStream.postBuffer(buf, BUF_SIZE);
    call ReadStream.read(10000);
  }
  
  event void Read.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      call Leds.led0On();
  }
  
#if 0
  async event void ReadNow.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      call Leds.led1On();
  }
#endif

  event void ReadStream.bufferDone( error_t result, 
			 uint16_t* buffer, uint16_t count )
  {
  }

  event void ReadStream.readDone(error_t result)
  {
    if (result == SUCCESS)
      call Leds.led2On();
  }
}

