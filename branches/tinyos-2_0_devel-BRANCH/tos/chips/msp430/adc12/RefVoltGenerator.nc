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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-31 00:19:31 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* Note: The reference voltage generator can be used in parallel by
 * multiple client application that request the same voltage level.
 * EVERY APPLICATION MUST CALL switchOff AFTER USAGE.
 */
includes  RefVoltGenerator;
interface RefVoltGenerator
{ 
  /* Switches on the reference voltage generator. Event isStable is
   * signalled when the refernce voltage is stable (max. after 17ms).
   *
   * @param voltageLevel either REFERENCE_1_5V or REFERENCE_2_5V 
   * (see RefVoltGenerator.h).
   *
   * @return SUCCESS if reference voltage generator was switched on,
   * FAIL otherwise (not reserved or ADC is busy).
  */ 
  async command result_t switchOn(uint8_t voltageLevel);
  
  /*
   * Turns the reference voltage generator off.
   *
   * @return FAIL if not switched on (or client has no access reserved)
   * SUCCESS otherwise
   */
  async command result_t switchOff();
  
  /**
   * Returns current voltage level.
   *
   * @return REFERENCE_1_5V if vref is stable 1.5 V
   *         REFERENCE_2_5V if vref is stable 2.5 V
   *         UNSTABLE if reference voltage generator is off or vref is unstable.
   *         (see RefVoltGenerator.h)
   */
  async command uint8_t getVoltageLevel();

  /*
   * Reference voltage is now stable.
   *
   * @param REFERENCE_1_5V if vref is 1.5 V
   *        REFERENCE_2_5V if vref is 2.5 V
   *        (see RefVoltGenerator.h)
   */
  event void isStable(uint8_t voltageLevel);
}

