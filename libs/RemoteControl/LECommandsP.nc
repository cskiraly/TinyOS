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

module LECommandsP
{
    provides interface DataCommand;
    uses
    {
				interface Init;
		    interface LinkEstimator as SubLE[radio_id_t radio_id];
		    command neighbor_table_entry_t *neighEntryIdx(uint8_t idx, radio_id_t rid);
		    command neighbor_table_entry_t *neighEntryAddr(uint16_t addr, radio_id_t rid);
    }
}
implementation
{
		typedef nx_struct cmd{
  		nx_uint8_t type;
		  nx_uint8_t radio_id;
  		nx_uint16_t param;
		} cmd_t;

		typedef nx_struct ret{
			nx_uint8_t flags;
			nx_uint16_t etx;
			nx_uint8_t inq;
		} ret_t;

	  uint16_t computeETX(uint8_t q1) {
  	  uint16_t q;
    	if (q1 == 0)
      	return 0xffff;
	    q =  2500 / q1;
  	  if (q > 250)
				q = 0xffff;
  		return q;
	  }

    command void DataCommand.execute(void *data, uint8_t length)
    {
				cmd_t *cmd = (cmd_t*)data;
				//get neighbor entry by idx: [idx radio]
        if (cmd->type==0 
						&& cmd->param < NEIGHBOR_TABLE_SIZE)
        {
					ret_t ret;
					neighbor_table_entry_t *ne = call neighEntryIdx(cmd->param, cmd->radio_id);
					if (ne) {
						ret.flags = ne->flags;
						ret.etx = ne->etx;
						ret.inq = ne->inquality;
					}
          signal DataCommand.ack (*((uint32_t*)&ret));
				}
				//get neigh entry by addr: [addr radio]
        else if (cmd->type==1 
						&& cmd->param != 0xFFFF)
        {
					ret_t ret;
					neighbor_table_entry_t *ne = call neighEntryAddr(cmd->param, cmd->radio_id);
					if (ne) {
						ret.flags = ne->flags;
						ret.etx = ne->etx;
						ret.inq = ne->inquality;
					}
          signal DataCommand.ack (*((uint32_t*)&ret));
				}
				//get link quality estimate of a node: [addr radio]
				else if (cmd->type==2)
				{
					signal DataCommand.ack(call SubLE.getLinkQuality[cmd->radio_id](cmd->param));
				}
				//print neigh table
				else if (cmd->type==3)
				{
#ifndef RC_SERIAL_OFF       
					uint8_t i=0;
					neighbor_table_entry_t *ne;
					printf("\nneigh of %d:\n", TOS_NODE_ID);
					printf("id \tfl \t-> \t<-\n");
					while ( (ne=call neighEntryIdx(i, cmd->radio_id))!=0)
					{
						printf("%d \t%d \t%d \t%d\n",
								ne->ll_addr, ne->flags, ne->etx, computeETX(ne->inquality));
						++i;
					}
					printfflush();
#endif //RC_SERIAL_OFF
				}
				//init tables
				else if (cmd->type==4)
					signal DataCommand.ack(call Init.init());
    }

		event void SubLE.evicted[radio_id_t radio_id](am_addr_t neighbor) {;}
}


