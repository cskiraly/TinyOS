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

module CC2420ReceiveP {

  provides interface Init;
  provides interface AsyncControl;
  provides interface CC2420Receive;
  provides interface Receive;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;

  uses interface Leds;

}

implementation {

  enum {
    S_STOPPED,
    S_STARTED,
    S_RX_HEADER,
    S_RX_PAYLOAD,
  };

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
  };

  uint16_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];
  uint8_t m_timestamp_head, m_timestamp_size;
  uint8_t m_missed_packets;

  norace uint8_t m_bytes_left;
  norace message_t* m_p_rx_buf;

  message_t m_rx_buf;
  uint8_t m_state;

  void beginReceive();
  void receive();
  void waitForNextPacket();
  task void receiveDone_task();

  cc2420_header_t* getHeader( message_t* msg ) {
    return (cc2420_header_t*)( msg->data - sizeof( cc2420_header_t ) );
  }
  
  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }
  
  command error_t Init.init() {
    m_p_rx_buf = &m_rx_buf;
    return SUCCESS;
  }

  void reset_state() {
    m_bytes_left = RXFIFO_SIZE;
    m_timestamp_head = m_timestamp_size = 0;
    m_missed_packets = 0;
  }

  async command error_t AsyncControl.start() {
    atomic {
      reset_state();
      m_state = S_STARTED;
      call InterruptFIFOP.enableFallingEdge();
    }
    return SUCCESS;
  }

  async command error_t AsyncControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }

  async command void CC2420Receive.sfd( uint16_t time ) {
    atomic {
      if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
	uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
			  TIMESTAMP_QUEUE_SIZE );
	m_timestamp_queue[ tail ] = time;
	m_timestamp_size++;
      }
    }
  }

  async command void CC2420Receive.sfd_dropped() {
    atomic {
      if ( m_timestamp_size )
	m_timestamp_size--;
    }
  }

  async event void InterruptFIFOP.fired() {
    if ( m_state == S_STARTED ) {
      m_state = S_RX_HEADER;
      beginReceive();
    }
    else {
      m_missed_packets++;
    }
  }
  
  void beginReceive() { 

    if ( call SpiResource.immediateRequest() == SUCCESS )
      receive();
    else {
      call SpiResource.request();
    }

  }
  
  event void SpiResource.granted() {
    receive();
  }

  void receive() {

    cc2420_header_t* header = getHeader( m_p_rx_buf );

    call CSN.clr();
    call RXFIFO.beginRead( (uint8_t*)header, 1 );

  }

  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
				    error_t error ) {

    cc2420_header_t* header = getHeader( m_p_rx_buf );
    cc2420_metadata_t* metadata = getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*)header;
    uint8_t length = buf[ 0 ];
    bool too_big;

    if ( m_state == S_RX_HEADER ) {
      m_state = S_RX_PAYLOAD;

      too_big = ( length + 1 > m_bytes_left );
      if ( !call FIFO.get() && !call FIFOP.get() )
	m_bytes_left -= rx_len + 1;

      if ( too_big ) {
	reset_state();
	call CSN.set();
	call CSN.clr();
	call SFLUSHRX.strobe();
	call SFLUSHRX.strobe();
	call CSN.set();
	call SpiResource.release();
	waitForNextPacket();
	return;
      }
      
      call RXFIFO.continueRead( (length < MAC_PACKET_SIZE) ? buf + 1 : NULL ,
				length );
    }

    else {

      call CSN.set();
      call SpiResource.release();
      
      if ( m_timestamp_size ) {
	if ( length > 10 ) {
	  metadata->time = m_timestamp_queue[ m_timestamp_head ];
	  m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
	  m_timestamp_size--;
	}
      }
      else {
	metadata->time = 0xffff;
      }
      
      // pass packet up if crc is good
      if ( ( buf[ length ] >> 7 ) && rx_buf ) {
	uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;
	signal CC2420Receive.receive( type, m_p_rx_buf );
	if ( type == IEEE154_TYPE_DATA ) {
	  post receiveDone_task();
	  return;
	}
      }
      
      waitForNextPacket();

    }

  }

  uint16_t flipBytes( uint16_t x ) {
    return ( x << 8 ) | ( x >> 8 );
  }

  task void receiveDone_task() {
    
    cc2420_header_t* header = getHeader( m_p_rx_buf );
    cc2420_metadata_t* metadata = getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*)header;
    uint8_t length = buf[ 0 ];
    
    header->dest = flipBytes( header->dest );
    header->destpan = flipBytes( header->destpan );
    header->src = flipBytes( header->src );
    metadata->crc = buf[ length ] >> 7;
    metadata->strength = buf[ length - 1 ];
    metadata->lqi = buf[ length ] & 0x7f;
    m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, 
					 length );

    waitForNextPacket();

  }

  void waitForNextPacket() {
    
    bool keep_receiving = FALSE;

    atomic {
      if ( m_state == S_STOPPED )
	return;

      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get() ) {
	if ( m_missed_packets )
	  m_missed_packets--;
	keep_receiving = TRUE;
	m_state = S_RX_HEADER;
      }
      else {
	m_state = S_STARTED;
	m_missed_packets = 0;
      }
    }      
    
    if ( keep_receiving )
      beginReceive();

  }

  async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}  

  event void SpiResource.requested() {}

}
