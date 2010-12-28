/*
* Copyright (c) 2006 Stanford University.
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
* - Neither the name of the Stanford University nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
* UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Brano Kusy (branislav.kusy@gmail.com)
 */

#include "RadioCommands.h"
#include <Tasklet.h>
#include "RF212DriverLayer.h"
#include "RF230DriverLayer.h"
module RadioCommandsP{
	provides{
		interface DataCommand as RadioCommand;
		interface IntCommand;
	}
	uses{
    interface Timer<TMilli>;
#ifdef USE_RF212_RADIO
		interface RF2xxConfig as RF212Config;
        interface RadioState as RF212State;
		interface GetSet<uint8_t>  as RF212GetSetState;
		command uint8_t readRF212Reg(uint8_t reg);
		command rf212_dbg_t getRF212Dbg();
#endif
#ifdef USE_RF230_RADIO
		interface RF2xxConfig as RF230Config;
        interface RadioState as RF230State;
        interface GetSet<uint8_t>  as RF230GetSetState;
		command uint8_t readRF230Reg(uint8_t reg);
       	command rf230_dbg_t getRF230Dbg();

#endif
//        interface Leds;
		interface RadioSelect;
	}
}

implementation{

    enum radio_cmds {
        CMD_NONE = 0,
        CMD_CHANGING_PHY_MODE_R_OFF = 1, // stage 1 turn the radio off
        CMD_CHANGING_PHY_MODE_R_ON = 2, // stage 2 turn the radio on again
				CMD_RESTART = 3,
    };

    tasklet_norace volatile uint8_t radio212_cmd = CMD_NONE; // remember what we are waiting for
    tasklet_norace volatile uint8_t radio230_cmd = CMD_NONE; // remember what we are waiting for
    tasklet_norace radio_cmd_t tmp_cmd; // a placeholder in case we use the radio

	command void IntCommand.execute(uint32_t param) {
#ifdef USE_RF230_RADIO
			rf230_dbg_t dbg230;
#endif
#ifdef USE_RF212_RADIO
			rf212_dbg_t dbg;
			radio212_cmd = CMD_NONE;
			dbg = call getRF212Dbg();
			//printf("212state:%d\n", call RF212GetSetState.get());
			if ((param & 0xFF) == 100)
				signal IntCommand.ack(call RF212GetSetState.get());
			else if ((param & 0xFF) == 101) {
				call RF212GetSetState.set(param>>8);
				signal IntCommand.ack(call RF212GetSetState.get());
			}	
			else if ((param & 0xFF) == 200)
				call RF212State.turnOff();
			else if ((param & 0xFF) == 201)
				call RF212State.turnOn();
			else if ((param & 0xFF) == 202) {
				radio212_cmd = CMD_RESTART;
				call RF212State.turnOff();
			}
#endif
#ifdef USE_RF230_RADIO
			radio230_cmd = CMD_NONE;
			dbg230 = call getRF230Dbg();
			//printf("230state:%d\n", call RF230GetSetState.get());
			if ((param & 0xFF) == 102)
				signal IntCommand.ack(call RF230GetSetState.get());
			else if ((param & 0xFF) == 103) {
				call RF230GetSetState.set(param>>8);
				signal IntCommand.ack(call RF230GetSetState.get());
			}	
			else if ((param & 0xFF) == 203)
				call RF230State.turnOff();
			else if ((param & 0xFF) == 204)
				call RF230State.turnOn();
			else if ((param & 0xFF) == 205) {
				radio230_cmd = CMD_RESTART;
				call RF230State.turnOff();
			}
#endif
	}

    /* NOTE: 212 = 0, 230 = 1 - we get it from the UI, not from the unique macro!!! */
	command void RadioCommand.execute(void *data, uint8_t length){
		radio_cmd_t *cmd = (radio_cmd_t*)data;
        memcpy(&tmp_cmd, cmd, sizeof(radio_cmd_t));

		if (cmd->type == RADIO_CMD_ANTENNA_SET){
            if(cmd->radio_id == 1){
            }
            
            // switch based on the radio
#ifdef USE_RF212_RADIO
            if(cmd->radio_id == 0){
    			call RF212Config.setAntenna(cmd->param);
			    signal RadioCommand.ack(call RF212Config.getAntenna());
            }
#endif
#ifdef USE_RF230_RADIO
            if(cmd->radio_id == 1){
    			call RF230Config.setAntenna(cmd->param);
			    signal RadioCommand.ack(call RF230Config.getAntenna());
            }
#endif
		}
		else if (cmd->type == RADIO_CMD_ANTENNA_GET){
			// switch based on the radio
#ifdef USE_RF212_RADIO
            if(cmd->radio_id == 0){
			    signal RadioCommand.ack(call RF212Config.getAntenna());
            }
#endif
#ifdef USE_RF230_RADIO
            if(cmd->radio_id == 1){
			    signal RadioCommand.ack(call RF230Config.getAntenna());
            }
#endif
		}

		else if (cmd->type == RADIO_CMD_FREQ_SET){
			signal RadioCommand.ack(0xffff);
		}
		else if (cmd->type == RADIO_CMD_FREQ_GET){
			signal RadioCommand.ack(0xffff);
		}

		else if (cmd->type == RADIO_CMD_PHY_SET){
            // for the modulation changes we need to use a timer as the network
            // should remain stable during flooding the change
            uint32_t delay = 5 * 1000; // 5 seconds delay
            call Timer.startOneShot(delay);
		}
		else if (cmd->type == RADIO_CMD_PHY_GET){
#ifdef USE_RF212_RADIO
            if(cmd->radio_id == 0){
			    signal RadioCommand.ack(call RF212Config.readPhyMode());
            }
#endif
#ifdef USE_RF230_RADIO
            if(cmd->radio_id == 1){
			    signal RadioCommand.ack(call RF230Config.readPhyMode());
            }
#endif
		}
		else if (cmd->type == RADIO_CMD_BAND_SET){
                        uint32_t delay = 5 * 1000; // 5 seconds delay
                        call Timer.startOneShot(delay);
		}
		else if (cmd->type == RADIO_CMD_BAND_GET){
			signal RadioCommand.ack(call RadioSelect.getDefaultRadio());
		}
    else if (cmd->type == RADIO_CMD_PLL_SYNC){
#ifdef USE_RF212_RADIO
      call RF212Config.resynchPLL();
			signal RadioCommand.ack(0);
#endif
#ifdef USE_RF230_RADIO
      call RF230Config.resynchPLL();
			signal RadioCommand.ack(0);
#endif 
        }
	}

    
    // for the modulation changes we need to use a timer as the network
    // should remain stable during flooding the change
    event void Timer.fired(){
        // switch based on the radio, note that this can be only done in TRX off state,
        // thus we have to cycle the radio
        if (tmp_cmd.type == RADIO_CMD_PHY_SET) {
#ifdef USE_RF212_RADIO
            if(tmp_cmd.radio_id == 0){
                radio212_cmd = CMD_CHANGING_PHY_MODE_R_OFF;
                call RF212Config.setPhyMode(tmp_cmd.param);
                call RF212State.turnOff();
            // we have to wait for the done event
            }
#endif
#ifdef USE_RF230_RADIO
            if(tmp_cmd.radio_id == 1){
                radio230_cmd = CMD_CHANGING_PHY_MODE_R_OFF;
                call RF230Config.setPhyMode(tmp_cmd.param);
                call RF230State.turnOff();
            // we have to wait for the done event
            }
#endif
        }
        else if (tmp_cmd.type == RADIO_CMD_BAND_SET) {
                call RadioSelect.setDefaultRadio(tmp_cmd.param);
		signal RadioCommand.ack(call RadioSelect.getDefaultRadio());
        }
    }


    // the radio state events we listen to
#ifdef USE_RF212_RADIO
    task void signalAck212(){
         signal RadioCommand.ack(call RF212Config.readPhyMode());
    }
    tasklet_async event void RF212State.done(){
        if(radio212_cmd == CMD_CHANGING_PHY_MODE_R_OFF){
            // radio is tuned off now, turn back on
            radio212_cmd = CMD_CHANGING_PHY_MODE_R_ON;
            call RF212State.turnOn();
        } else if(radio212_cmd == CMD_CHANGING_PHY_MODE_R_ON){
    	    radio212_cmd = CMD_NONE;
            post signalAck212();
        }
				else if (radio212_cmd == CMD_RESTART){
					radio212_cmd = CMD_NONE;
					call RF212State.turnOn();
				}
    }
#endif
#ifdef USE_RF230_RADIO
    task void signalAck230(){
        signal RadioCommand.ack(call RF230Config.readPhyMode());
    }
    tasklet_async event void RF230State.done(){
        if(radio230_cmd == CMD_CHANGING_PHY_MODE_R_OFF){
            // radio is tuned off now, turn back on
            radio230_cmd = CMD_CHANGING_PHY_MODE_R_ON;
            call RF230State.turnOn();
        } else if(radio230_cmd == CMD_CHANGING_PHY_MODE_R_ON){
    	    radio230_cmd = CMD_NONE;
            post signalAck230();
        }
				else if (radio230_cmd == CMD_RESTART){
					radio230_cmd = CMD_NONE;
					call RF230State.turnOn();
				}
    }
#endif
 
}
