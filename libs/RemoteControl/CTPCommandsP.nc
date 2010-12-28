#include <TreeRouting.h>

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

module CTPCommandsP
{
    provides interface DataCommand;
    provides interface IntCommand;
    uses
    {
		    interface CtpInfo;
				interface GetSet<uint8_t>  as RouterState;
				interface GetSet<uint8_t>  as ForwarderState;
  			command routing_table_entry *neighEntryIdx(uint8_t idx);
  			command routing_table_entry *neighEntryAddr(uint16_t addr);
				command void routingInit();
				command error_t fwdRestart();
    }
}
implementation
{
		typedef nx_struct cmd{
  		nx_uint8_t type;
  		nx_uint16_t param;
		} cmd_t;

		typedef nx_struct ret{
			nx_uint8_t neigh;
			nx_uint8_t parent;
			nx_uint8_t rid;
			nx_uint8_t etx;
		} ret_t;
		typedef nx_struct ret2{
			nx_uint16_t parent;
			nx_uint16_t etx;
		} ret2_t;

		inline uint8_t cap8bit(uint16_t in) { return (in<255)?in:255;}

    command void IntCommand.execute(uint32_t param) 
		{
			if ((param & 0xFF) == 100)
				signal IntCommand.ack(call RouterState.get());
			else if ((param & 0xFF) == 101) {
				call RouterState.set(param>>8);
				signal IntCommand.ack(call RouterState.get());
			}	
			else if ((param & 0xFF) == 102)
				signal IntCommand.ack(call ForwarderState.get());
			else if ((param & 0xFF) == 103) {
				call ForwarderState.set(param>>8);
				signal IntCommand.ack(call ForwarderState.get());
			}	

		}

    command void DataCommand.execute(void *data, uint8_t length)
    {
				cmd_t *cmd = (cmd_t*)data;
				//get neighbor entry by idx
        if (cmd->type==0)
        {
					ret_t ret;
					routing_table_entry *ne = call neighEntryIdx(cmd->param);
					if (ne) {
						ret.neigh = cap8bit(ne->neighbor);
						ret.parent = cap8bit(ne->info.parent);
						//ret.rid = ne->info.radio_id;
						ret.etx = cap8bit(ne->info.etx);
					}
          signal DataCommand.ack (*((uint32_t*)&ret));
				}
				//get neigh entry by addr
        else if (cmd->type==1)
        {
					ret_t ret;
					routing_table_entry *ne = call neighEntryAddr(cmd->param);
					if (ne) {
						ret.neigh = cap8bit(ne->neighbor);
						ret.parent = cap8bit(ne->info.parent);
						//ret.rid = ne->info.radio_id;
						ret.etx = cap8bit(ne->info.etx);
					}
          signal DataCommand.ack (*((uint32_t*)&ret));
				}
				//get current parent and etx
				else if (cmd->type==2)
				{
					ret2_t ret;
					am_addr_t parent=0;
					uint16_t etx;
					call CtpInfo.getParent(&parent); 
					call CtpInfo.getEtx(&etx);
					ret.parent=parent;
					ret.etx=etx; 
          signal DataCommand.ack (*((uint32_t*)&ret));
				}
				//print neigh table
				else if (cmd->type==3)
				{
#ifndef RC_SERIAL_OFF       
					uint8_t i=0;
					am_addr_t parent=0;
					uint16_t etx;
					uint8_t rid=0;
					routing_table_entry *ne;
					call CtpInfo.getParent(&parent); 
					//call CtpInfo.getEtxAndRadio(&etx, &rid);
					call CtpInfo.getEtx(&etx);
					printf("\n%d: p=%d etx=%d rid=%d\n", 
							TOS_NODE_ID, parent, etx, rid);
					printf("id \tp_id \trid \tetx\n");
					while ( (ne=call neighEntryIdx(i))!=0)
					{
						printf("%d \t%d \t%d \t%d\n",
								ne->neighbor, ne->info.parent, /*ne->info.radio_id*/0, ne->info.etx);
						++i;
					}
					printfflush();
#endif
				}
				//run commands
				else if (cmd->type==4) {
					if (cmd->param==0)
						call routingInit();
					else if (cmd->param==1)
						call fwdRestart();
					else if (cmd->param==2)
						call CtpInfo.triggerImmediateRouteUpdate();
					else if (cmd->param==3)
						call CtpInfo.recomputeRoutes();
					signal DataCommand.ack(1);
				}
    }
}


