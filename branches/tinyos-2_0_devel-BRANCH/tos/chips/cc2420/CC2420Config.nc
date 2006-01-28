/**
 * Copyright (c) 2005-2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * An HAL abstraction of the ChipCon CC2420 radio. This abstraction
 * deals specifically with radio configurations.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.4 $ $Date: 2006-01-28 01:39:29 $
 */

interface CC2420Config {

  /**
   * Start the voltage regulator on the CC2420. On SUCCESS,
   * <code>startVReg()</code> will be signalled when the voltage
   * regulator is fully on.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t startVReg();

  /**
   * Signals that the voltage regulator has been started.
   */
  async event void startVRegDone();
  
  /**
   * Stop the voltage regulator immediately.
   *
   * @return SUCCESS always
   */
  async command error_t stopVReg();

  /**
   * Start the oscillator. On SUCCESS, <code>startOscillator</code>
   * will be signalled when the oscillator has been started.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t startOscillator();

  /**
   * Signals that the oscillator has been started.
   */
  async event void startOscillatorDone();

  /**
   * Stop the oscillator.
   *
   * @return SUCCESS if the oscillator was stopped, FAIL otherwise.
   */
  async command error_t stopOscillator();

  /**
   * Enable RX.
   *
   * @return SUCCESS if receive mode has been enabled, FAIL otherwise.
   */
  async command error_t rxOn();

  /**
   * Disable RX.
   *
   * @return SUCCESS if receive mode has been disabled, FAIL otherwise.
   */
  async command error_t rfOff();

  /**
   * @return SUCCESS if the channel was set successfully, FAIL
   * otherwise.
   */
  async command error_t setChannel( uint8_t channel );

  /**
   * Change the transmit power of the CC2420 radio.
   *
   * @param power power to transmit. Valid values are 0 - 31.
   * @return SUCCESS if the transmit power was set successfully, FAIL
   * otherwise.
   */
  async command error_t setTxPower( uint8_t power );

}
