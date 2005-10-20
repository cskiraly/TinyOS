/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: SensorMts300P.nc,v 1.1.2.1 2005-10-20 04:44:07 mturon Exp $
 */

includes Timer;

module SensorMts300P
{
    provides {
	interface Init;                 //!< Standard Initialization
	interface StdControl;           //!< Start/Stop for Power Management
	interface AcquireData as Temp;  //!< Thermister
	interface AcquireData as Light; //!< Photo sensor
    }

    uses {
	interface GeneralIO as TempPower;
	interface GeneralIO as LightPower;
	interface AcquireData as SensorADC;
	interface Timer<TMilli> as WarmUpTimer;
    }
}
implementation 
{
    enum {
	STATE_IDLE = 0,
	STATE_LIGHT_WARMING,   //!< Powering on sensor
	STATE_LIGHT_READY,     //!< Power up of sensor complete
	STATE_LIGHT_SAMPLING,  //!< Sampling sensor
	STATE_TEMP_WARMING,    //!< Powering on sensor
	STATE_TEMP_READY,      //!< Power up of sensor complete
	STATE_TEMP_SAMPLING,   //!< Sampling sensor
    };

    union {
	uint8_t flat;
	struct {
	    uint8_t state       : 4;   //!< sensorboard state
	} bits;
    } g_flags;

   /**
    * Initialize this component. Initialization should not assume that
    * any component is running: init() cannot call any commands besides
    * those that initialize other components. 
    *
    */
    command error_t Init.init() {
	g_flags.flat = STATE_IDLE;
    }

    /**
     * Start the component and its subcomponents.
     *
     * @return SUCCESS if the component was successfully started.
     */
    command error_t StdControl.start() {
    }
    
    /**
     * Stop the component and pertinent subcomponents (not all
     * subcomponents may be turned off due to wakeup timers, etc.).
     *
     * @return SUCCESS if the component was successfully stopped.
     */
    command error_t StdControl.stop() {
	call TempPower.clr();
	call LightPower.clr();
	call TempPower.makeInput();
	call LightPower.makeInput();
	atomic g_flags.bits.state = STATE_IDLE;
    }

    /** Turns on the light sensor and turns the thermistor off. */
    void switchLightOn() {
	atomic g_flags.bits.state = STATE_LIGHT_WARMING;
	call TempPower.clr();
	call TempPower.makeInput();
	call LightPower.makeOutput();
	call LightPower.set();
	call WarmUpTimer.startOneShot(10);
    }

    /** Turns on the thermistor and turns the light sensor off. */
    void switchTempOn() {
	atomic g_flags.bits.state = STATE_TEMP_WARMING;
	call LightPower.clr();
	call LightPower.makeInput();
	call TempPower.makeOutput();
	call TempPower.set();
	call WarmUpTimer.startOneShot(10);
    }

    task void getLightSample() {
	switch (g_flags.bits.state) {
	    case STATE_TEMP_WARMING:
	    case STATE_TEMP_READY:
	    case STATE_TEMP_SAMPLING:
		// If Temperature is busy, repost and try again later.
		post getLightSample();
		return;

	    case STATE_IDLE: 
		// Okay, grab the sensor.
		switchLightOn();
		return;
		
	    case STATE_LIGHT_WARMING:
		// Warm-up Timer will switch out of this state.
		return;

	    case STATE_LIGHT_READY:
		// Start the sample.
		atomic { g_flags.bits.state = STATE_LIGHT_SAMPLING; }
		call SensorADC.getData();
		return;

	    case STATE_LIGHT_SAMPLING:
		// SensorADC.dataReady will switch out of this state.
		return;
	}
    }

    task void getTempSample() {
	switch (g_flags.bits.state) {
	    case STATE_LIGHT_WARMING:
	    case STATE_LIGHT_READY:
	    case STATE_LIGHT_SAMPLING:
		// If Temperature is busy, repost and try again later.
		post getLightSample();
		return;

	    case STATE_IDLE: 
		// Okay, grab the sensor.
		switchLightOn();
		return;
		
	    case STATE_TEMP_WARMING:
		// Warm-up Timer will switch out of this state.
		return;

	    case STATE_TEMP_READY:
		// Start the sample.
		atomic { g_flags.bits.state = STATE_LIGHT_SAMPLING; }
		call SensorADC.getData();
		return;

	    case STATE_TEMP_SAMPLING:
		// SensorADC.dataReady will switch out of this state.
		return;
	}
    }

    /** 
     * Start Temperature data acquisition.  
     *
     *   This will post a task which will handle sequential states:
     *      WARMING, READY, SAMPLING, DONE (IDLE)
     *   and repost itself until it is completed.
     *
     * @return SUCCESS if request accepted, EBUSY if it is refused
     *    'dataReady' or 'error' will be signaled if SUCCESS is returned
     */
    command error_t Temp.getData() {
	post getTempSample();	
	return SUCCESS;
    }

    /** 
     * Start Light data acquisition.
     *
     *   This will post a task which will handle sequential states:
     *      WARMING, READY, SAMPLING, DONE (IDLE)
     *   and repost itself until it is completed.
     *
     *  @return SUCCESS if request accepted, EBUSY if it is refused
     *    'dataReady' or 'error' will be signaled if SUCCESS is returned
     */
    command error_t Light.getData() {
	post getLightSample();	
	return SUCCESS;
    }

    /** 
     * Timer to allow either thermistor or light sensor to warm up for 10 msec.
     */
    event void WarmUpTimer.fired() {
	switch (g_flags.bits.state) {
	    case STATE_LIGHT_WARMING:
		atomic { g_flags.bits.state = STATE_LIGHT_READY; }
		post getLightSample();
		return;

	    case STATE_TEMP_WARMING:
		atomic { g_flags.bits.state = STATE_TEMP_READY; }
		post getTempSample();
		return;

	    default:
		//ERROR!!!
		signal Light.error(-1);
		signal Temp.error(-1);
      	}
	// Worst case -- return to the IDLE state so next task can progress !!
	atomic { g_flags.bits.state = STATE_IDLE; }
    }

    /** 
     * Data has been acquired.
     * @param data Acquired value
     *   Values are "left-justified" within each 16-bit integer, i.e., if
     *   the data is acquired with n bits of precision, each value is 
     *   shifted left by 16-n bits.
     */
    event void SensorADC.dataReady(uint16_t data) {
	switch (g_flags.bits.state) {
	    case STATE_LIGHT_SAMPLING:
		signal Light.dataReady(data);
		break;

	    case STATE_TEMP_SAMPLING:
		signal Temp.dataReady(data);
		break;

	    default:
		//ERROR!!!
		signal Light.error(data);
		signal Temp.error(data);
      	}
	// ADC.dataReady must return to IDLE state so next task can progress !!
	atomic { g_flags.bits.state = STATE_IDLE; }
    }


    /** 
     * Signal that the data acquisition failed
     * @param info error information
     */
    event void SensorADC.error(uint16_t info) {
	switch (g_flags.bits.state) {
	    case STATE_LIGHT_SAMPLING:
		signal Light.error(info);
		break;

	    case STATE_TEMP_SAMPLING:
		signal Temp.error(info);
		break;

	    default:
		//ERROR!!!
		signal Light.error(info);
		signal Temp.error(info);
      	}
	// ADC.dataReady must return to IDLE state so next task can progress !!
	atomic { g_flags.bits.state = STATE_IDLE; }
    }
}





