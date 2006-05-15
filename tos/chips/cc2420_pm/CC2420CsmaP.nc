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
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.1 $ $Date: 2006-05-15 19:46:05 $
 */

module CC2420CsmaP {

  provides interface Init;
  provides interface SplitControl;
  provides interface Send;
  provides interface PacketAcknowledgements as Acks;
  provides interface RadioPowerControl;
  provides interface ChannelMonitor;

  uses interface Resource;
  uses interface ReceiveNotification;
  uses interface CC2420Config;
  uses interface AsyncStdControl as SubControl;
  uses interface CC2420Transmit;
  uses interface CsmaBackoff;
  uses interface Random;
  uses interface AMPacket;
  uses interface Leds;
  //uses interface Counter<TMicro,uint16_t> as Timer;
  uses interface Counter<T32khz,uint32_t> as Timer;
}

implementation {

  enum {
    S_PREINIT,
    S_STOPPED,
    S_STARTING,
    S_IDLE,
    S_STARTED,
    S_STOPPING,
    S_TRANSMIT,
  };

  //GX
  uint32_t sleepStart=0;
  message_t* m_msg;
  uint8_t m_state = S_PREINIT;
  uint8_t m_dsn;
  error_t sendErr = SUCCESS;
  
  struct {
    uint8_t receiveBusy : 1 ;
    uint8_t shouldTurnOn : 1 ;
    uint8_t shouldTurnOff : 1 ;
  } f; //for flags
  
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();
  void checkTurnOnOff();

  cc2420_header_t* getHeader( message_t* msg ) {
    return (cc2420_header_t*)( msg->data - sizeof( cc2420_header_t ) );
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

  task void powerOnSuccess() {
    signal RadioPowerControl.onDone(SUCCESS);
  }
  task void powerOffSuccess() {
    signal RadioPowerControl.offDone(SUCCESS);
  }
  task void powerOnFail() {
    signal RadioPowerControl.onDone(FAIL);
  }
  task void powerOffFail() {
    signal RadioPowerControl.offDone(FAIL);
  }

  command error_t Init.init() {
    
    if ( m_state != S_PREINIT )
      return FAIL;

    atomic {
      m_state = S_STOPPED;
      f.receiveBusy = FALSE;
      f.shouldTurnOn = FALSE;
      f.shouldTurnOff = FALSE;
    }

    return SUCCESS;

  }

  command error_t SplitControl.start() {

    if ( m_state != S_STOPPED ) 
      return FAIL;

    atomic m_state = S_STARTING;

    m_dsn = call Random.rand16();
    call CC2420Config.startVReg();
    return SUCCESS;

  }

  async command void RadioPowerControl.on() {
    bool tempRxBusy;
    atomic tempRxBusy = f.receiveBusy;
    switch (m_state) {
      case S_STARTED:
        post powerOnSuccess();
        break;
      case S_IDLE:
        if(tempRxBusy == FALSE) {
          call Resource.request();
          break;
        }
      case S_TRANSMIT:
       atomic f.shouldTurnOn = TRUE;
       break;
      default:
        post powerOnFail();
    }
  }

  async command void RadioPowerControl.off() {
    bool tempRxBusy;
    atomic tempRxBusy = f.receiveBusy;
    switch (m_state) {
      case S_IDLE:
        post powerOffSuccess();
        break;
      case S_STARTED:
        if(tempRxBusy == FALSE) {
          call Resource.request();
          post powerOffSuccess();
        }
      case S_TRANSMIT:
        atomic f.shouldTurnOff = TRUE;
        break;
      default:
        post powerOffFail();
    }
  }

  command void ChannelMonitor.check() {
    signal ChannelMonitor.error();
  }

  async event void CC2420Config.startVRegDone() {
    call Resource.request();
  }

  event void Resource.granted() {
    switch(m_state) {
      case S_STARTING:
        call CC2420Config.startOscillator();
        break;
      case S_IDLE:
        call CC2420Config.rxOn();
	    
		//GX
		atomic{
			if(sleepStart){
				sleepTime += call Timer.get()-sleepStart;
				sleepStart = 0;
			}			
		}

        atomic m_state = S_STARTED;
        atomic f.shouldTurnOn = FALSE;
        call Resource.release();
        signal RadioPowerControl.onDone(SUCCESS);
        break;
      case S_STARTED:
        call CC2420Config.rfOff();
   		
		//GX
		atomic{
			if(countStart) sleepStart = call Timer.get();
		}
		atomic m_state = S_IDLE;
        atomic f.shouldTurnOff = FALSE;
        call Resource.release();
        break;
    }
  }

  async event void Timer.overflow(){ 
	  /*atomic {
		  if(sleepStart) sleepTime += (uint16_t)65535-sleepStart;
		  sleepStart = 0;
	  } */
  }

  async event void CC2420Config.startOscillatorDone() {
    call SubControl.start();
    call CC2420Config.rxOn();
    call Resource.release();
    post startDone_task();
  }

  task void startDone_task() {
    atomic m_state = S_STARTED;
    signal SplitControl.startDone( SUCCESS );
  }

  command error_t SplitControl.stop() {

    if ( m_state != S_STARTED )
      return FAIL;

    atomic m_state = S_STOPPING;

    call SubControl.stop();
    call CC2420Config.stopVReg();
    post stopDone_task();

    return SUCCESS;

  }

  task void stopDone_task() {
    atomic m_state = S_STOPPED;
    signal SplitControl.stopDone( SUCCESS );
  }

  async command error_t Acks.requestAck( message_t* msg ) {
    getHeader( msg )->fcf |= 1 << IEEE154_FCF_ACK_REQ;
    return SUCCESS;
  }
  
  async command error_t Acks.noAck( message_t* msg ) {
    getHeader( msg )->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
    return SUCCESS;
  }
  
  async command bool Acks.wasAcked( message_t* msg ) {
    return getMetadata( msg )->ack;
  }

  command error_t Send.cancel( message_t* p_msg ) {
    return FAIL;
  }

  command error_t Send.send( message_t* p_msg, uint8_t len ) {
    
    cc2420_header_t* header = getHeader( p_msg );
    cc2420_metadata_t* metadata = getMetadata( p_msg );

    atomic {
      if ( m_state != S_STARTED || f.shouldTurnOff == TRUE)
        return FAIL;
      m_state = S_TRANSMIT;
      m_msg = p_msg;
      header->dsn = ++m_dsn;
    }

    header->length = len;
    header->fcf = ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
                    ( 1 << IEEE154_FCF_INTRAPAN ) |
                    ( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
                    ( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) );
    if ( header->dest != AM_BROADCAST_ADDR )
      header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
    header->src = call AMPacket.address();
    metadata->ack = FALSE;
    metadata->strength = 0;
    metadata->lqi = 0;
    metadata->time = 0;

    call CC2420Transmit.sendCCA( m_msg );

    return SUCCESS;

  }

  command void* Send.getPayload(message_t* m) {
    return m->data;
  }

  command uint8_t Send.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  async event uint16_t CsmaBackoff.initial( message_t* m ) {
    return ( call Random.rand16() & 0x1f ) + 1;
  }

  async event uint16_t CsmaBackoff.congestion( message_t* m ) {
    return ( call Random.rand16() & 0x7 ) + 1;
  }

  async event void CC2420Transmit.sendDone( message_t* p_msg, error_t err ) {
    atomic sendErr = err;
    post sendDone_task();
  }

  task void sendDone_task() {
    error_t packetErr;
    atomic packetErr = sendErr;
    atomic {
      m_state = S_STARTED;
      checkTurnOnOff();
    }
    signal Send.sendDone( m_msg, packetErr );
  }

  void checkTurnOnOff() {
    atomic {
      if(f.shouldTurnOn == TRUE)
        call RadioPowerControl.on();
      if(f.shouldTurnOff == TRUE)
        call RadioPowerControl.off();
    }
  }

  async event void ReceiveNotification.receiveStarting() { atomic f.receiveBusy = TRUE; }
  async event void ReceiveNotification.receiveDone() {
    atomic {
      f.receiveBusy = FALSE;
      checkTurnOnOff();
    }
  }
  async event void ReceiveNotification.receiveCancelled() { 
    atomic {
      f.receiveBusy = FALSE;
      checkTurnOnOff();
    }
  }

  default async event void ChannelMonitor.busy() { 
  }

  default async event void ChannelMonitor.free() { 
  }

  default event void RadioPowerControl.onDone(error_t error) {
  }

  default event void RadioPowerControl.offDone(error_t error) {
  }

}

