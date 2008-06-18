/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
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
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Jung Il Choi Initial SACK implementation
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @version $Revision: 1.2 $ $Date: 2008-06-18 15:39:32 $
 */

#include "CC2420.h"
#include "crc.h"
#include "message.h"

module CC2420TransmitP {

  provides interface Init;
  provides interface AsyncStdControl;
/*    interface CC2420Transmit;*/
  provides interface CC2420Tx;
/*  provides interface RadioBackoff;*/
/*  provides interface RadioTimeStamping as TimeStamp;*/
/*  provides interface ReceiveIndicator as EnergyIndicator;*/
/*  provides interface ReceiveIndicator as ByteIndicator;*/
  
/*  uses interface Alarm<T32khz,uint32_t> as BackoffAlarm;*/
  uses interface Alarm<T62500hz,uint32_t> as BackoffAlarm;
  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

/*  uses interface Resource as SpiResource;*/
  uses interface ChipSpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Strobe as SACKPEND; // JH: ACKs must have pending flag set
  uses interface CC2420Register as MDMCTRL1;
  uses interface CaptureTime;
  uses interface ReferenceTime;

  uses interface CC2420Receive;
  uses interface Leds;
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
  
/*  norace message_t *m_msg;*/
  norace ieee154_txframe_t *m_data;
  norace uint8_t m_txFrameLen;
  ieee154_reftime_t m_timestamp;
  
  cc2420_transmit_state_t m_state = S_STOPPED;
  
  bool m_receiving = FALSE;
  
  uint16_t m_prev_time;
  
  /** Byte reception/transmission indicator */
  bool sfdHigh;
  
  /** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
  norace bool abortSpiRelease;
  
  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  

  /***************** Prototypes ****************/
  error_t load( ieee154_txframe_t *data );
  error_t resend( bool cca );
  void loadTXFIFO();
  void attemptSend(bool cca);
  void congestionBackoff();
  error_t acquireSpiResource();
  error_t releaseSpiResource();
/*  void signalDone( error_t err );*/
  void signalDone( bool ackFramePending, error_t err );
/*  void cancelTx();*/
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  /***************** AsyncStdControl Commands ****************/
  async command error_t AsyncStdControl.start() {
    atomic {
      if (m_state == S_STARTED)
        return EALREADY;
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
    }
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call BackoffAlarm.stop();
      call CaptureSFD.disable();
/*      call SpiResource.release();  // REMOVE*/
      call CSN.set();
    }
    return SUCCESS;
  }


  /**************** Send Commands ****************/

/*  async command error_t Send.send( message_t* p_msg, bool useCca ) {*/
  async command error_t CC2420Tx.loadTXFIFO(ieee154_txframe_t *data) {
    return load( data);
  }

  async command void CC2420Tx.send(bool cca)
  {
    attemptSend(cca);
  }
  
  async command bool CC2420Tx.cca()
  {
    return call CCA.get();
  }

  async command error_t CC2420Tx.modify( uint8_t offset, uint8_t* buf, 
                                     uint8_t len ) {
    call CSN.set();
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }
  
  async command void CC2420Tx.lockChipSpi()
  {
    abortSpiRelease = TRUE;
  }
  async command void CC2420Tx.unlockChipSpi()
  {
    abortSpiRelease = FALSE;
  }

  /***************** Indicator Commands ****************/
/*  command bool EnergyIndicator.isReceiving() {*/
/*    return !(call CCA.get());*/
/*  }*/
/*  */
/*  command bool ByteIndicator.isReceiving() {*/
/*    bool high;*/
/*    atomic high = sfdHigh;*/
/*    return high;*/
/*  }*/
  

  /***************** RadioBackoff Commands ****************/
  /**
   * Must be called within a requestInitialBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
/*  async command void RadioBackoff.setInitialBackoff(uint16_t backoffTime) {*/
/*    myInitialBackoff = backoffTime + 1;*/
/*  }*/
  
  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
/*  async command void RadioBackoff.setCongestionBackoff(uint16_t backoffTime) {*/
/*    myCongestionBackoff = backoffTime + 1;*/
/*  }*/
  
/*  async command void RadioBackoff.setCca(bool useCca) {*/
/*  }*/
  
  
  
  /**
   * The CaptureSFD event is actually an interrupt from the capture pin
   * which is connected to timing circuitry and timer modules.  This
   * type of interrupt allows us to see what time (being some relative value)
   * the event occurred, and lets us accurately timestamp our packets.  This
   * allows higher levels in our system to synchronize with other nodes.
   *
   * Because the SFD events can occur so quickly, and the interrupts go
   * in both directions, we set up the interrupt but check the SFD pin to
   * determine if that interrupt condition has already been met - meaning,
   * we should fall through and continue executing code where that interrupt
   * would have picked up and executed had our microcontroller been fast enough.
   */
  async event void CaptureSFD.captured( uint16_t time ) {
    // "time" is from TimerB capture, which is sourced by SMCLK (1MHz)
    //P2OUT &= ~0x40;      // debug: P2.6 low
    uint32_t localTime;
    atomic {
      switch( m_state ) {
        
      case S_SFD:
        m_state = S_EFD;
        sfdHigh = TRUE;
        call CaptureTime.convert(time, &m_timestamp, -8); // -8 for the preamble
        call CaptureSFD.captureFallingEdge();
/*        signal TimeStamp.transmittedSFD( time, m_msg );*/
        localTime = call ReferenceTime.toLocalTime(&m_timestamp);
        signal CC2420Tx.transmittedSFD(localTime, m_data );
        //if ( (call CC2420PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
        //if ( (m_data->header)[0] & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          // This is an ack packet, don't release the chip's SPI bus lock.
        //}
        releaseSpiResource();
        call BackoffAlarm.stop();
        m_data->metadata->timestamp = localTime;

        
/*        if ( ( ( (call CC2420PacketBody.getHeader( m_msg ))->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == IEEE154_TYPE_DATA ) {*/
/*          (call CC2420PacketBody.getMetadata( m_msg ))->time = time;*/
/*        }*/
        
        if ( call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        
/*        if ( (call CC2420PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {*/
        if ( (m_data->header->mhr)[0] & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          m_state = S_ACK_WAIT;
          call BackoffAlarm.start( 200 ); // we need to have *completely* received the ACK
        } else {
          signalDone(FALSE, SUCCESS);
        }
        
        if ( !call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      default:
        if ( !m_receiving ) {
          sfdHigh = TRUE;
          call CaptureSFD.captureFallingEdge();
/*          signal TimeStamp.receivedSFD( time );*/
          call CaptureTime.convert(time, &m_timestamp, -8);
          call CC2420Receive.sfd( &m_timestamp );
          m_receiving = TRUE;
          m_prev_time = time;
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
        }
        
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        m_receiving = FALSE;
/*        if ( time - m_prev_time < 10 ) {*/
#ifdef PIERCEBOARD_ENABLED
        if ( time - m_prev_time < 10*30 ) {
#else
        if ( time - m_prev_time < 10 ) {
#endif
          call CC2420Receive.sfd_dropped();
        }
        break;
      
      }
    }
  }

  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
    if(abortSpiRelease) {
      call ChipSpiResource.abortRelease();
    }
  }
  
  
  /***************** CC2420Receive Events ****************/
  /**
   * If the packet we just received was an ack that we were expecting,
   * our send is complete.
   */
  async event void CC2420Receive.receive(  uint8_t type, message_t *ackFrame ){
/*  async event void CC2420Receive.receive( uint8_t type, message_t* ack_msg ) {*/
/*    cc2420_header_t* ack_header;*/
/*    cc2420_header_t* msg_header;*/
/*    cc2420_metadata_t* msg_metadata;*/
/*    uint8_t* ack_buf;*/
/*    uint8_t length;*/

    atomic {
      if ( type == IEEE154_TYPE_ACK ) {

        /*      ack_header = call CC2420PacketBody.getHeader( ack_msg );*/
        /*      msg_header = call CC2420PacketBody.getHeader( m_msg );*/

        /*      if ( m_state == S_ACK_WAIT && msg_header->dsn == ack_header->dsn ) {*/
        if (  m_state == S_ACK_WAIT && 
            m_data->header->mhr[2] == ((ieee154_header_t*) ackFrame->header)->mhr[2] ) { // compare seqno
          call BackoffAlarm.stop();

          /*        msg_metadata = call CC2420PacketBody.getMetadata( m_msg );*/
          /*        ack_buf = (uint8_t *) ack_header;*/
          /*        length = ack_header->length;*/
          /*        */
          /*        msg_metadata->ack = TRUE;*/
          /*        msg_metadata->rssi = ack_buf[ length - 1 ];*/
          /*        msg_metadata->lqi = ack_buf[ length ] & 0x7f;*/
          signalDone(( ((ieee154_header_t*) ackFrame->header)->mhr[0] & 0x10) ? TRUE: FALSE, SUCCESS);
        }
      }
    }
  }

  /***************** SpiResource Events ****************/
    /*
  event void SpiResource.granted() {
    uint8_t cur_state;

    atomic {
      cur_state = m_state;
    }

    switch( cur_state ) {
    case S_LOAD:
      loadTXFIFO();
      break;
      
    case S_BEGIN_TRANSMIT:
      attemptSend();
      break;
      
    case S_CANCEL:
      cancelTx();
      break;
      
    default:
      releaseSpiResource();
      break;
    }
  }
  */
  
  /***************** TXFIFO Events ****************/
  /**
   * The TXFIFO is used to load packets into the transmit buffer on the
   * chip
   */
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
                                     error_t error ) {

    call CSN.set();
    
    if (tx_buf == &m_txFrameLen){
      // until here: 1.65 ms
      call CSN.clr();
      call TXFIFO.write( m_data->header->mhr, m_data->headerLen );
      return;
    } else if (tx_buf == m_data->header->mhr) {
      // until here: 2.2 ms
      call CSN.clr();
      call TXFIFO.write( m_data->payload, m_data->payloadLen );
      return;
    }
    // until here: 4.6 ms (no DMA on USART0)
    // until here: 3.3 ms (with DMA on USART0)
    // P2OUT &= ~0x40;      // P2.1 low 
    
/*    if ( m_state == S_CANCEL ) {*/
/*      atomic {*/
/*        call CSN.clr();*/
/*        call SFLUSHTX.strobe();*/
/*        call CSN.set();*/
/*      }*/
/*      releaseSpiResource();*/
/*      m_state = S_STARTED;*/
            
/*    } else if ( !m_cca ) {*/
/*    } else  {*/
      m_state = S_BEGIN_TRANSMIT;
      releaseSpiResource();
      signal CC2420Tx.loadTXFIFODone(m_data, error);
/*      attemptSend();*/
/*    }*/

/*    } else {*/
/*      releaseSpiResource();*/
/*      atomic {*/
/*        if (m_state == S_LOAD_CANCEL) {*/
/*          m_state = S_CCA_CANCEL;*/
/*        } else {*/
/*          m_state = S_SAMPLE_CCA;*/
/*        }*/
/*      }*/
/*      signal CC2420Tx.loadTXFIFODone(m_data, error);*/
      
/*      signal RadioBackoff.requestInitialBackoff(m_msg);*/
/*      call BackoffAlarm.start(myInitialBackoff);*/
/*    }*/
  }

  
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }
  
  
  /***************** Timer Events ****************/
  /**
   * The backoff timer is mainly used to wait for a moment before trying
   * to send a packet again. But we also use it to timeout the wait for
   * an acknowledgement, and timeout the wait for an SFD interrupt when
   * we should have gotten one.
   */
  async event void BackoffAlarm.fired() {
    atomic {
      switch( m_state ) {
        
      case S_SAMPLE_CCA : 
        // sample CCA and wait a little longer if free, just in case we
        // sampled during the ack turn-around window
        if ( call CCA.get() ) {
          m_state = S_BEGIN_TRANSMIT;
          call BackoffAlarm.start( CC2420_TIME_ACK_TURNAROUND );
          
        } else {
          congestionBackoff();
        }
        break;
        
      case S_BEGIN_TRANSMIT:
      case S_CANCEL:
        // should never happen
        call Leds.led0On();
/*        if ( acquireSpiResource() == SUCCESS ) {*/
/*          attemptSend();*/
/*        }*/
        break;
        
      case S_ACK_WAIT:
/*        signalDone( SUCCESS );*/
        signalDone( FALSE, FAIL );
        break;

      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        atomic {
          call CSN.set();
          call CSN.clr();
          call SFLUSHTX.strobe();
          call CSN.set();
        }
        signalDone( FALSE, ERETRY );
        releaseSpiResource();
        //call CaptureSFD.captureRisingEdge();
        break;

      default:
        break;
      }
    }
  }

  /***************** Functions ****************/
  /**
   * Set up a message to be sent. First load it into the outbound tx buffer
   * on the chip, then attempt to send it.
   * @param *p_msg Pointer to the message that needs to be sent
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  error_t load( ieee154_txframe_t *data) {
    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_state = S_LOAD;
/*      m_msg = p_msg;*/
      m_data = data;
      totalCcaChecks = 0;
    }
    
    if ( acquireSpiResource() == SUCCESS ) {
      loadTXFIFO();
    }

    return SUCCESS;
  }
  
  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
/*  error_t resend( bool cca ) {*/

/*    atomic {*/
/*      if (m_state == S_LOAD_CANCEL*/
/*          || m_state == S_CCA_CANCEL*/
/*          || m_state == S_TX_CANCEL) {*/
/*        return ECANCEL;*/
/*      }*/
/*      */
/*      if ( m_state != S_STARTED ) {*/
/*        return FAIL;*/
/*      }*/
/*      */
/*      m_cca = cca;*/
/*      m_state = cca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;*/
/*      totalCcaChecks = 0;*/
/*    }*/
/*    */
/*    if(m_cca) {*/
/*      signal RadioBackoff.requestInitialBackoff(m_msg);*/
/*      call BackoffAlarm.start( myInitialBackoff );*/
/*      */
/*    } else if ( acquireSpiResource() == SUCCESS ) {*/
/*      attemptSend();*/
/*    }*/
/*    */
/*    return SUCCESS;*/
/*  }*/
  
  /**
   * Attempt to send the packet we have loaded into the tx buffer on 
   * the radio chip.  The STXONCCA will send the packet immediately if
   * the channel is clear.  If we're not concerned about whether or not
   * the channel is clear (i.e. m_cca == FALSE), then STXON will send the
   * packet without checking for a clear channel.
   *
   * If the packet didn't get sent, then congestion == TRUE.  In that case,
   * we reset the backoff timer and try again in a moment.
   *
   * If the packet got sent, we should expect an SFD interrupt to take
   * over, signifying the packet is getting sent.
   */
  void attemptSend(bool cca) {
    uint8_t status;
    bool congestion = TRUE;

    atomic {
      call CSN.set();
      call CSN.clr();

      // STXONCCA costs about ? symbols, i.e. attemptSend should be called
      // ? symbols, before the actual CCA
      //P2OUT |= 0x40;      // P2.6 high
      status = cca ? call STXONCCA.strobe() : call STXON.strobe();
      //status = call STXON.strobe();
      //U0TXBUF = 0x04; // strobe STXON
      //while (!(IFG1 & URXIFG0));
      //status = U0RXBUF;
      //call CSN.set();

      if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
        status = call SNOP.strobe();
        if ( status & CC2420_STATUS_TX_ACTIVE ) {
          congestion = FALSE;
        }
      }
      
      call CSN.set();
      // debug: on telosb SFD is connected to Pin P4.1
      if (!congestion) {while (!(P4IN & 0x02)) ;  P6OUT &= ~0x80;}

      if (congestion){
        call ReferenceTime.getNow(&m_timestamp, 0);
        m_state = S_BEGIN_TRANSMIT; // don't use a state S_SAMPLE_CCA
        releaseSpiResource();
        signal CC2420Tx.sendDone(m_data, &m_timestamp, FALSE, EBUSY); // waiting for the next send()
      } else {
        m_state = S_SFD; // wait for an ACK
        signal CC2420Tx.transmissionStarted(m_data);
        call BackoffAlarm.start(CC2420_ABORT_PERIOD*3);
      }
      return; // we still own the SPI, either we wait for an ACK or resend is going to be called soon
    }
    
/*    if ( congestion ) {*/
/*      totalCcaChecks = 0;*/
/*      releaseSpiResource();*/
/*      congestionBackoff();*/
/*    } else {*/
/*      call BackoffAlarm.start(CC2420_ABORT_PERIOD);*/
/*    }*/
  }
  
  /**  
   * Congestion Backoff
   */
  void congestionBackoff() {
    atomic {
/*      signal RadioBackoff.requestCongestionBackoff(m_msg);*/
      call BackoffAlarm.start(myCongestionBackoff);
    }
  }
  
  error_t acquireSpiResource() {
    return SUCCESS;
    /*
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
    */
  }

  error_t releaseSpiResource() {
    //call SpiResource.release();
    return SUCCESS;
  }


  /** 
   * Setup the packet transmission power and load the tx fifo buffer on
   * the chip with our outbound packet.  
   *
   * Warning: the tx_power metadata might not be initialized and
   * could be a value other than 0 on boot.  Verification is needed here
   * to make sure the value won't overstep its bounds in the TXCTRL register
   * and is transmitting at max power by default.
   *
   * It should be possible to manually calculate the packet's CRC here and
   * tack it onto the end of the header + payload when loading into the TXFIFO,
   * so the continuous modulation low power listening strategy will continually
   * deliver valid packets.  This would increase receive reliability for
   * mobile nodes and lossy connections.  The crcByte() function should use
   * the same CRC polynomial as the CC2420's AUTOCRC functionality.
   */
  void loadTXFIFO() {
/*    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_msg );*/
/*    uint8_t tx_power = (call CC2420PacketBody.getMetadata( m_msg ))->tx_power;*/
    m_txFrameLen = m_data->headerLen + m_data->payloadLen + 2;

/*    if ( !tx_power ) {*/
/*      tx_power = CC2420_DEF_RFPOWER;*/
/*    }*/
    call CSN.set();
    call CSN.clr();
    call SFLUSHTX.strobe(); // flush out anything that was in there
    call CSN.set();
    call CSN.clr();
    
/*    call TXFIFO.write( (uint8_t*)header, header->length - 1);*/
    call TXFIFO.write( &m_txFrameLen, 1 );

  }
  
  void signalDone( bool ackFramePending, error_t err ) {
    atomic m_state = S_STARTED;
    signal CC2420Tx.sendDone( m_data, &m_timestamp, ackFramePending, err );
    call ChipSpiResource.attemptRelease();
/*    signal Send.sendDone( m_msg, err );*/
  }
  
  /***************** Tasks ****************/

  /***************** Defaults ****************/
/*  default async event void TimeStamp.transmittedSFD( uint16_t time, message_t* p_msg ) {*/
/*  }*/
  
/*  default async event void TimeStamp.receivedSFD( uint16_t time ) {*/
/*  }*/

}

