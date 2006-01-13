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
 * $Revision: 1.1.2.4 $
 * $Date: 2006-01-13 18:46:17 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * Tests the AdcC and switches on LED1, LED2 and LED3 if the test is
 * successful: 
 * LED1 denotes a successful Read operation, 
 * LED2 denotes a successful ReadNow operation, 
 * LED3 denotes a successful ReadStream operation.  
 *
 * Requires a DemoSensorC component that provides Read<uint16_t>,
 * ReadNow<uint16_t> and ReadStream<uint16_t>
 * 
 * Author: Jan Hauer 
 */

configuration TestAdcAppC {
}
implementation
{
  components MainC, 
             TestAdcC, 
             new DemoSensorC() as Sensor, 
             LedsC;

  TestAdcC -> MainC.Boot;
  MainC.SoftwareInit -> LedsC;
  TestAdcC.Leds -> LedsC;
  TestAdcC.Read -> Sensor;
  TestAdcC.ReadNow -> Sensor;
  TestAdcC.ReadStream -> Sensor;
}

