/**
 * Copyright (c) 2005 Arched Rock Corporation
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
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 *
 * $ Revision: $
 * $ Date: $
 */

module CC2420TransmitP {

  provides interface Init;
  provides interface AsyncControl;
  provides interface CC2420Transmit as Send;
  provides interface CSMABackoff;
  provides interface RadioTimeStamping as TimeStamp;

  uses interface Alarm<T32khz,uint16_t> as BackoffTimer;
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

  uses interface CC2420Receive;
  uses interface Leds;

}

implementation {

  enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_SAMPLE_CCA,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
    S_CANCEL,
  };

  norace message_t* m_msg;
  norace bool m_cca;
  uint8_t m_state = S_STOPPED;
  bool m_have_resource = FALSE;
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

  error_t acquireSpiResource() {

    atomic {
      if ( m_have_resource || 
	   call SpiResource.immediateRequest() == SUCCESS ) {
	m_have_resource = TRUE;
	return SUCCESS;
      }
    }
    call SpiResource.request();

    return FAIL;

  }

  void releaseSpiResource() {
    atomic {
      if ( m_have_resource ) {
	m_have_resource = FALSE;
	call SpiResource.release();
      }
    }
  }

  void signalDone() {
    atomic m_state = S_STARTED;
    signal Send.sendDone( m_msg );
  }

  command error_t Init.init() {
    return SUCCESS;
  }

  async command error_t AsyncControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
    }
    return SUCCESS;
  }

  async command error_t AsyncControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call BackoffTimer.stop();
      call CaptureSFD.disable();
    }
    return SUCCESS;
  }

  error_t send( message_t* p_msg, bool cca ) {

    atomic {
      if ( m_state != S_STARTED )
	return FAIL;
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
    }

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

    if ( m_cca ) {
      call BackoffTimer.start( signal CSMABackoff.initial( m_msg ) * 
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

    call BackoffTimer.stop();

    atomic {
      switch( m_state ) {
      case S_LOAD:
	m_state = ( !m_have_resource ) ? S_STARTED : S_CANCEL;
	break;
      case S_SAMPLE_CCA: case S_BEGIN_TRANSMIT:
	m_state = S_STARTED;
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
    }
    else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      attemptSend();
    }
    else {
      releaseSpiResource();
      m_state = S_SAMPLE_CCA;
      call BackoffTimer.start( signal CSMABackoff.initial( m_msg ) * 
			       CC2420_BACKOFF_PERIOD );
    }

  }

  void congestionBackoff() {
    atomic {
      uint16_t time = signal CSMABackoff.congestion( m_msg );
      if ( time )
	call BackoffTimer.start( time * CC2420_BACKOFF_PERIOD );
      else
	m_state = S_STARTED;
    }
  }

  async event void BackoffTimer.fired() {

    uint8_t cur_state;

    atomic cur_state = m_state;

    switch( cur_state ) {
      
    case S_SAMPLE_CCA :
      // sample CCA and wait a little longer if free, just in case we
      // sampled during the ack turn-around window
      if ( call CCA.get() ) {
	atomic m_state = S_BEGIN_TRANSMIT;
	call BackoffTimer.start( CC2420_TIME_ACK_TURNAROUND );
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
      signalDone();
      break;

    }

  }

  void attemptSend() {

    uint8_t status;

    call CSN.clr();
    
    if ( m_cca )
      call STXONCCA.strobe();
    else
      call STXON.strobe();

    status = call SNOP.strobe();

    call CSN.set();

    if ( status & CC2420_STATUS_TX_ACTIVE ) {
      atomic m_state = S_SFD;
    }
    else {
      releaseSpiResource();
      congestionBackoff();
    }

  }

  async command error_t Send.modify( uint8_t offset, uint8_t* buf, 
				     uint8_t len ) {
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }

  async event void CaptureSFD.captured( uint16_t time ) {

    uint8_t cur_state;
    bool cur_receiving;

    atomic {
      cur_state = m_state;
      cur_receiving = m_receiving;
    }

    switch( cur_state ) {
      
    case S_SFD:
      call CaptureSFD.captureFallingEdge();
      signal TimeStamp.transmittedSFD( time, m_msg );
      releaseSpiResource();
      if ( ( ( getHeader( m_msg )->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == 
	   IEEE154_TYPE_DATA )
	getMetadata( m_msg )->time = time;
      atomic m_state = S_EFD;
      if ( call SFD.get() )
	break;
      
    case S_EFD:
      call CaptureSFD.captureRisingEdge();
      if ( getHeader( m_msg )->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
	atomic m_state = S_ACK_WAIT;
	call BackoffTimer.start( CC2420_ACK_WAIT_DELAY );
      }
      else {
	signalDone();
      }
      if ( !call SFD.get() )
	break;
      
    default:
      
      if ( !cur_receiving ) {
	call CaptureSFD.captureFallingEdge();
	signal TimeStamp.receivedSFD( time );
	call CC2420Receive.sfd( time );
	atomic { 
	  cur_receiving = m_receiving = TRUE;
	  m_prev_time = time;
	}
	if ( call SFD.get() )
	  return;
      }
      if ( cur_receiving ) {
	call CaptureSFD.captureRisingEdge();
	atomic {
	  m_receiving = FALSE;
	  if ( time - m_prev_time < 10 )
	    call CC2420Receive.sfd_dropped();
	}
      }
      
      break;
      
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
	call BackoffTimer.stop();
	msg_metadata->ack = TRUE;
	msg_metadata->strength = ack_buf[ length - 1 ];
	msg_metadata->lqi = ack_buf[ length ] & 0x7f;
	signalDone();
      }
    }

  }

  event void SpiResource.granted() {

    uint8_t cur_state;

    atomic {
      m_have_resource = TRUE;
      cur_state = m_state;
    }

    switch( cur_state ) {
    case S_LOAD: loadTXFIFO(); break;
    case S_BEGIN_TRANSMIT: attemptSend(); break;
    default: releaseSpiResource(); break;
    }

  }

  event void SpiResource.requested() {}
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}

  default async event void TimeStamp.transmittedSFD( uint16_t time, message_t* p_msg ) {}
  default async event void TimeStamp.receivedSFD( uint16_t time ) {}

}
