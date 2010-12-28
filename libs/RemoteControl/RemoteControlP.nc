/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Brano Kusy
 */
#include "RemoteControl.h"

module RemoteControlP
{
    provides interface RemCtlInfo;
    provides interface StdControl;
		provides command void sendIntCommand(uint8_t type, uint32_t param);

    uses
    {
        interface IntCommand[uint8_t id];
        interface DataCommand[uint8_t id];
        
        interface Boot;
        interface StdControl as CollectionControl;
        
        interface Receive;
#ifndef RC_SERIAL_OFF       
				interface Receive as SerialReceive;
#endif
#ifdef USE_MULTI_RADIO
				interface RadioSelect;
#endif
        interface AMSend;
        interface Packet;
        interface Send as AckSend;
        interface Timer<TMilli>;
        interface Random;
        interface Leds;
    }
}

implementation
{

    uint8_t sentSeqNum;
    uint8_t lastAppId;
    uint8_t lastMsgSerial=0;
    enum
    {
      UNDEFINED_SEQ = 0x80
    };

    uint8_t state;
    enum
    {
        STATE_BUSY = 0x00,
        STATE_FORWARDED = 0x01,
        STATE_EXECUTED = 0x02,
        STATE_ACKED = 0x04,
        STATE_IDLE = 0x07,
        STATE_STOPPED= 0x08,
    };

    message_t ctlMsg;
    message_t ackMsg;

    uint8_t execTimer;
    uint32_t ackReturnValue;


    event void Boot.booted()
    {
			control_msg_t *ctlData = call AMSend.getPayload(&ctlMsg, sizeof(control_msg_t));
      state = STATE_STOPPED;
      sentSeqNum = UNDEFINED_SEQ;
      ctlData->seqNum = UNDEFINED_SEQ;
    }

    command error_t StdControl.start()
    {
      execTimer = 0;
      state = STATE_IDLE;
      call CollectionControl.start();
			return SUCCESS;
    }
    command error_t StdControl.stop() 
		{
      state = STATE_STOPPED;
			call Timer.stop();
			return SUCCESS;
		}

    void _receive(void *payload, uint8_t len);
   
		//send an int command with no effort, uses one higher seq number than the last one, 0xffff destination
		command void sendIntCommand(uint8_t appId, uint32_t param){
      control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, 6);
			control_msg_t data;
			data.seqNum = controlData->seqNum+1;
			data.target = 0xFFFF;
			data.dataType = 0; 
			data.appId = appId;
			*((nx_uint32_t*)data.data) = param;
			lastMsgSerial=0;
			_receive(&data, 9);
		}
  
		uint8_t forwarding = 0; 
    void task forward()
    {
        control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, call Packet.payloadLength(&ctlMsg));
				if (forwarding)
					return;
#ifdef USE_MULTI_RADIO
				call RadioSelect.selectRadio(&ctlMsg,0);
#endif 
        if (sentSeqNum != controlData->seqNum)
        {
						//printf("RCtl%d:tx\n", 0);
            if (call AMSend.send(AM_BROADCAST_ADDR, &ctlMsg, call Packet.payloadLength(&ctlMsg))==SUCCESS)
							forwarding = 1;
            sentSeqNum = controlData->seqNum;
        }
#ifdef USE_MULTI_RADIO
				if (!forwarding)
					signal AMSend.sendDone(&ctlMsg, FAIL);
#else
        state |= STATE_FORWARDED;
#endif
        //call Leds.led1Toggle();
    }

    event void AMSend.sendDone(message_t *msg, error_t error) {
#ifdef USE_MULTI_RADIO
				uint8_t id = call RadioSelect.getRadio(&ctlMsg);
				//printf("Rctl%d:txd\n", id);
				if (id == 0)
				{
					call RadioSelect.selectRadio(&ctlMsg,id+1);
					//printf("RCtl%d:tx\n", id+1);
					if(call AMSend.send(AM_BROADCAST_ADDR, &ctlMsg, call Packet.payloadLength(&ctlMsg))!=SUCCESS)
						signal AMSend.sendDone(&ctlMsg, FAIL);
				}
				else
	        state |= STATE_FORWARDED;
				if (state & STATE_FORWARDED)
#endif	
					forwarding = 0;
		}

    void task execute()
    {
        control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, call Packet.payloadLength(&ctlMsg));
        state |= STATE_ACKED;
        if( controlData->dataType == 0 )     // IntCommand
        {
            uint32_t val = *(nx_uint32_t*)controlData->data;
            call IntCommand.execute[lastAppId](val);
        }
        else if( controlData->dataType == 1 )    // DataCommand
            call DataCommand.execute[lastAppId](controlData->data,
                call Packet.payloadLength(&ctlMsg) - sizeof(control_msg_t));
        state |= STATE_EXECUTED;
    }
    
    void task sendAck()
    {
        control_ack_t *ackData = call AckSend.getPayload(&ackMsg, sizeof(control_ack_t));
        control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, call Packet.payloadLength(&ctlMsg));
        ackData->nodeId = TOS_NODE_ID;
        ackData->seqNum = controlData->seqNum;
        ackData->ret = ackReturnValue;
        call AckSend.send(&ackMsg, sizeof(control_ack_t));
        state |= STATE_ACKED;
    }

    event void Timer.fired() {
        if (execTimer>0)
            --execTimer;

        if(!(state & STATE_FORWARDED))
            post forward();
        else if (execTimer==0)
        {
            if (!(state & STATE_EXECUTED))
                post execute();
            else if (!(state & STATE_ACKED))
                post sendAck();
        }
        
        if (state==STATE_IDLE && !execTimer)
           call Timer.stop();
    }

    event void AckSend.sendDone(message_t* msg, error_t error) {}


    void _receive(void *payload, uint8_t len)
    {
        control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, len);
        control_msg_t *newData = payload;
        int8_t age = newData->seqNum - controlData->seqNum;
				//RC can get stuck if radiosend returns success but senddone never fires (e.g., if board
				//is disconnected, this small heck resets the RC component to workable state
				if (newData->seqNum == 178) 
					state=STATE_IDLE;
        if (newData->seqNum == UNDEFINED_SEQ || state != STATE_IDLE)
          return;

        if( age <= -10 || 0 < age || controlData->seqNum == UNDEFINED_SEQ )
        {
            state = STATE_BUSY;
            lastAppId = newData->appId;
            memcpy(controlData, payload, len);
            call Packet.setPayloadLength(&ctlMsg, len);
            call Timer.startPeriodic(50);
            if( newData->target == TOS_NODE_ID || newData->target == AM_BROADCAST_ADDR)
                execTimer = (call Random.rand16() & 0x3)+2;
            else
                state |= STATE_ACKED|STATE_EXECUTED;
        }
    }

#ifndef RC_SERIAL_OFF       
    event message_t* SerialReceive.receive(message_t* msg, void *payload, uint8_t len)
    {
        lastMsgSerial=1;
				_receive(payload, len);
        return msg;
    }
#endif
    event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len)
    {
        lastMsgSerial=0;
				_receive(payload, len);
        return msg;
    }

    void setAck(uint32_t retVal)
    {
        if (state==STATE_IDLE)
            call Timer.startPeriodic(50);
        state &= ~STATE_ACKED;
        ackReturnValue = retVal;
    }

    event void IntCommand.ack[uint8_t appId](uint32_t returnValue)
    {
        if (state!=STATE_IDLE && appId!=lastAppId)
            return;
        setAck(returnValue);
    }

    event void DataCommand.ack[uint8_t appId](uint32_t returnValue)
    {
        if (state!=STATE_IDLE && appId!=lastAppId)
            return;
        setAck(returnValue);
    }

    command uint8_t RemCtlInfo.getSeqNum()
    {
        control_msg_t *controlData = call AMSend.getPayload(&ctlMsg, call Packet.payloadLength(&ctlMsg));
        uint8_t seq = controlData->seqNum;
        return seq;
    }
    command uint8_t RemCtlInfo.isLastMsgSerial()
    {
        return lastMsgSerial;
    }

    default command void IntCommand.execute[uint8_t appId](uint32_t param) {}
    default command void DataCommand.execute[uint8_t appId](void *data, uint8_t length) {}
}
