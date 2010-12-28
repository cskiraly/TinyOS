/*
 * Author: Brano Kusy
 */
module ResetCommandsP{
    provides{
        interface IntCommand as ResetCommand;
        interface IntCommand as WatchdogCommand;
				interface Init;
				command void sendKeepAlive();
    }
    uses{
        interface Timer<TMilli>;
        interface Timer<TMilli> as AliveTimer;
        interface Random;
				interface Leds;
				interface Reset;
				command void sendIntCommand(uint8_t type, uint32_t param);
    }
}

implementation{
		enum{
	  	DEFAULT_WATCHDOG_PERIOD = 120,//20min
		};
		uint16_t count = 0;
		uint16_t watchdog_period = DEFAULT_WATCHDOG_PERIOD;

		command void sendKeepAlive(){
			call sendIntCommand(0x28, 0xFFFF); 
		}

		command error_t Init.init() {
				//call AliveTimer.startPeriodic(10240);//10sec
				return SUCCESS;
 		}
    
		command void WatchdogCommand.execute(uint32_t param){
			if (param == 0) {
				//disable watchdog
				call AliveTimer.stop();
				call Leds.led2Off();
				signal WatchdogCommand.ack(0);
			}
			else if (param == 0xFFFF){
				//keepalive msg from the base station
				count = 0;
			}
			else if (param == 0xFFFE)
				signal WatchdogCommand.ack(count);
			else {
				call AliveTimer.startPeriodic(10240);
				count = 0;
				watchdog_period = param;
				signal WatchdogCommand.ack(param);
			}
		}

    command void ResetCommand.execute(uint32_t param){
        uint32_t delay = (call Random.rand16() & 2047) | 1024;
        delay *= param;
        call Timer.startOneShot(delay);
        signal ResetCommand.ack(delay);
    }

    event void Timer.fired(){
			call Reset.reset();
    }

		event void AliveTimer.fired() {
			call Leds.led2Toggle();
			if (++count >= watchdog_period) {
				call Leds.led0Toggle();
				call Reset.reset();
			}
		}

}


