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

module CC2420TransmitP {

  provides interface Init;
  provides interface AsyncStdControl;
  provides interface CC2420Transmit as Send;
  provides interface CsmaBackoff;
  provides interface RadioTimeStamping as TimeStamp;
  provides interface SendNotification;
  provides interface PreambleLength;

  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;

  uses interface CC2420Receive;
  uses interface Leds;

  //uses interface Timer<TMilli> as Timer;
  //uses interface Counter<TMicro,uint16_t> as Timer;
  uses interface Counter<T32khz,uint32_t> as Timer;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_SAMPLE_CCA,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
    S_CANCEL,
  } cc2420_transmit_state_t;

  // This specifies how many jiffies the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2420_ABORT_PERIOD = 320
  };
  //GX
  uint32_t txStart=0;
  norace message_t* m_msg;
  norace bool m_cca;
  cc2420_transmit_state_t m_state = S_STOPPED;
  bool m_receiving = FALSE;
  uint16_t m_prev_time;

  void loadTXFIFO();
  void attemptSend();

  cc2420_header_t* getHeader( message_t* msg ) {
    return (cc2420_header_t*)( msg->data - sizeof( cc2420_header_t ) );
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

  void startBackoffTimer(uint16_t time) {
    call BackoffTimer.start(time);
  }

  void stopBackoffTimer() {
    call BackoffTimer.stop();
  }

  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS )
      call SpiResource.request();
    return error;
  }

  void releaseSpiResource() {
    call SpiResource.release();
  }

  void signalDone( error_t err ) {
    atomic m_state = S_STARTED;
    signal Send.sendDone( m_msg, err );
    signal SendNotification.sendDone(m_msg);
  }

  command error_t Init.init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  async command error_t AsyncStdControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
    }
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      stopBackoffTimer();
      call CaptureSFD.disable();
    }
    return SUCCESS;
  }

  async command void PreambleLength.set(uint16_t bytes) {
  }

  async command uint16_t PreambleLength.get() {
    return 6;
  }

  error_t send( message_t* p_msg, bool cca ) {

    atomic {
      if ( m_state != S_STARTED )
	return FAIL;
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
    }

    signal SendNotification.sendStarting(p_msg);
    if ( acquireSpiResource() == SUCCESS )
      loadTXFIFO();

    return SUCCESS;

  }

  async command error_t Send.sendCCA( message_t* p_msg ) {
    return send( p_msg, TRUE );
  }

  async command error_t Send.send( message_t* p_msg ) {
    return send( p_msg, FALSE );
  }

  error_t resend( bool cca ) {

    atomic {
      if ( m_state != S_STARTED )
	return FAIL;
      m_cca = cca;
      m_state = cca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
    }

    signal SendNotification.sendStarting(m_msg);
    if ( m_cca ) {
      startBackoffTimer( signal CsmaBackoff.initial( m_msg ) * 
			       CC2420_BACKOFF_PERIOD );
    }
    else if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
    
    return SUCCESS;
  
  }
  
  async command error_t Send.resendCCA() {
    return resend( TRUE );
  }

  async command error_t Send.resend() {
    return resend( FALSE );
  }

  async command error_t Send.cancel() {

    stopBackoffTimer();

    atomic {
      switch( m_state ) {
      case S_LOAD:
	m_state = S_CANCEL;
	break;
      case S_SAMPLE_CCA: case S_BEGIN_TRANSMIT:
	m_state = S_STARTED;
  signal SendNotification.sendCancelled(m_msg);
	break;
      default:
	// cancel not allowed while radio is busy transmitting
	return FAIL;
      }
    }

    return SUCCESS;

  }

  void loadTXFIFO() {
    cc2420_header_t* header = getHeader( m_msg );
    call CSN.clr();
    call TXFIFO.write( (uint8_t*)header, header->length - 1 );
  }
  
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
				     error_t error ) {

    call CSN.set();

    if ( m_state == S_CANCEL ) {
      m_state = S_STARTED;
      signal SendNotification.sendCancelled(m_msg);
    }
    else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      attemptSend();
    }
    else {
      releaseSpiResource();
      m_state = S_SAMPLE_CCA;
      startBackoffTimer( signal CsmaBackoff.initial( m_msg ) * 
			 CC2420_BACKOFF_PERIOD );
    }

  }

  void congestionBackoff() {
    atomic {
      uint16_t time = signal CsmaBackoff.congestion( m_msg );
      if ( time )
	startBackoffTimer( time * CC2420_BACKOFF_PERIOD );
      else
	m_state = S_STARTED;
  signal SendNotification.sendCancelled(m_msg);
    }
  }

  async event void BackoffTimer.fired() {

    atomic {
      switch( m_state ) {
	
      case S_SAMPLE_CCA :
	// sample CCA and wait a little longer if free, just in case we
	// sampled during the ack turn-around window
	if ( call CCA.get() ) {
	  m_state = S_BEGIN_TRANSMIT;
	  startBackoffTimer( CC2420_TIME_ACK_TURNAROUND );
	}
	else {
	  congestionBackoff();
	}
	break;
	
      case S_BEGIN_TRANSMIT :
	if ( acquireSpiResource() == SUCCESS )
	  attemptSend();
	break;
	
      case S_ACK_WAIT :
	signalDone( SUCCESS );
	break;
	
#ifdef PLATFORM_MICAZ
      case S_SFD:
	// We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
	// jiffies. Assume something is wrong.
	call SFLUSHTX.strobe();
	call CaptureSFD.disable();
	call CaptureSFD.captureRisingEdge();
	signalDone( ERETRY );
	break;
#endif
      default:
	break;
      }
    }

  }
  //GX
  async event void Timer.overflow(){ 
	  /*atomic {
		  if(txStart) txTime += (uint16_t)65535-txStart;
		  txStart=0;
	  }*/ 
  }
  void attemptSend() {

    uint8_t status;
    bool congestion = TRUE;

    call CSN.clr();

    status = m_cca ? call STXONCCA.strobe() : call STXON.strobe();
    if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
      status = call SNOP.strobe();
      if ( status & CC2420_STATUS_TX_ACTIVE )
	congestion = FALSE;
	  //GX
	  atomic {if(countStart) txStart = call Timer.get();}
    }
    atomic m_state = congestion ? S_SAMPLE_CCA : S_SFD;
    
    call CSN.set();

    if ( congestion ) {
      releaseSpiResource();
      congestionBackoff();
    }
#ifdef PLATFORM_MICAZ
    else {
      startBackoffTimer(CC2420_ABORT_PERIOD);
    }
#endif

  }

  async command error_t Send.modify( uint8_t offset, uint8_t* buf, 
				     uint8_t len ) {
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }

  async event void CaptureSFD.captured( uint16_t time ) {

    atomic {
      switch( m_state ) {
	
      case S_SFD:
	call CaptureSFD.captureFallingEdge();
	signal TimeStamp.transmittedSFD( time, m_msg );
	releaseSpiResource();
	stopBackoffTimer();
	m_state = S_EFD;
	if ( ( ( getHeader( m_msg )->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == 
	     IEEE154_TYPE_DATA )
	  getMetadata( m_msg )->time = time;
	if ( call SFD.get() )
	  break;
	
      case S_EFD:
	call CaptureSFD.captureRisingEdge();
	if ( getHeader( m_msg )->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
	  m_state = S_ACK_WAIT;
	  startBackoffTimer( CC2420_ACK_WAIT_DELAY );
	}
	else {
		//GX
		atomic{
			if(txStart){
				txTime += call Timer.get() - txStart; 
				txStart=0; 
			}
		}
	  signalDone(SUCCESS);
	}
	if ( !call SFD.get() )
	  break;
	
      default:
	if ( !m_receiving ) {
	  call CaptureSFD.captureFallingEdge();
	  atomic{ if(countStart) rxStart = call Timer.get(); }
	  signal TimeStamp.receivedSFD( time );
	  call CC2420Receive.sfd( time );
	  m_receiving = TRUE;
	  m_prev_time = time;
	  if ( call SFD.get() )
	    return;
	}
	if ( m_receiving ) {
	  call CaptureSFD.captureRisingEdge();
	  m_receiving = FALSE;
	  if ( time - m_prev_time < 10 )
	    call CC2420Receive.sfd_dropped();
	}
	break;
      
      }
    }
  }

  async event void CC2420Receive.receive( uint8_t type, message_t* ack_msg ) {

    if ( type == IEEE154_TYPE_ACK ) {
      cc2420_header_t* ack_header = getHeader( ack_msg );
      cc2420_header_t* msg_header = getHeader( m_msg );
      cc2420_metadata_t* msg_metadata = getMetadata( m_msg );
      uint8_t* ack_buf = (uint8_t*)ack_header;
      uint8_t length = ack_header->length;
      
      if ( m_state == S_ACK_WAIT &&
	   msg_header->dsn == ack_header->dsn ) {
	stopBackoffTimer();
	msg_metadata->ack = TRUE;
	msg_metadata->strength = ack_buf[ length - 1 ];
	msg_metadata->lqi = ack_buf[ length ] & 0x7f;
	signalDone(SUCCESS);
      }
    }

  }

  event void SpiResource.granted() {

    uint8_t cur_state;

    atomic {
      cur_state = m_state;
    }

    switch( cur_state ) {
    case S_LOAD: loadTXFIFO(); break;
    case S_BEGIN_TRANSMIT: attemptSend(); break;
    default: releaseSpiResource(); break;
    }

  }

  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}

  default async event void TimeStamp.transmittedSFD( uint16_t time, message_t* p_msg ) {}
  default async event void TimeStamp.receivedSFD( uint16_t time ) {}

  default async event uint16_t PreambleLength.query() { 
    return 6;
  }

  default async event void SendNotification.sendStarting(message_t* msg) {}
  default async event void SendNotification.sendDone(message_t* msg) {}
  default async event void SendNotification.sendCancelled(message_t* msg) {}

}
