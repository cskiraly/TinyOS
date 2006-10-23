/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-10-23 23:11:50 $ 
 */

#include "printf.h"

generic module PrintfP(uint16_t max_buffer_size) {
  provides {
    interface SplitControl as PrintfControl;
    interface Printf;
  }
  uses {
  	interface SplitControl as SerialControl;
    interface Leds;
    interface AMSend;
    interface Packet;
  }
}
implementation {
	
  enum {
  	S_STARTED,
  	S_STOPPED,
  	S_FLUSHING,
  };
  
  message_t printfMsg;
  nx_uint8_t buffer[max_buffer_size];
  norace nx_uint8_t* next_byte;
  uint8_t state = S_STOPPED;
  uint8_t bytes_left_to_flush;
  uint8_t length_to_send;
  
  task void retrySend() {
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, length_to_send) != SUCCESS)
      post retrySend();
  }

  void memcpy(uint8_t* src, nx_uint8_t* dest, uint8_t length) {
    int i;
    for(i=0; i<length; i++)
      dest[i] = src[i];
  }
  
  inline char getAsciiDigit(uint8_t digit) {
  	return digit + 48;
  }
  
  void uint8_to_string(uint8_t i, nx_uint8_t* buf) {
  	uint8_t string[3]; //Uint8 has maximum 3 digits
  	uint8_t length=0;
  	do {
  		string[length++] = getAsciiDigit(i % 10);
  		i /= 10;
  	} while(i != 0);
  	for(i=0; i<length; i++) {
      *next_byte = string[length-1-i];
  	  next_byte++;
  	}
  }
  
  void uint16_to_string(uint16_t i, nx_uint8_t* buf) {
  	uint8_t string[5]; //Uint16 has maximum 5 digits
  	uint8_t length=0;
  	do {
  		string[length++] = getAsciiDigit(i % 10);
  		i /= 10;
  	} while(i != 0);
  	for(i=0; i<length; i++) {
      *next_byte = string[length-1-i];
  	  next_byte++;
  	}
  }
  
  void uint32_to_string(uint32_t i, nx_uint8_t* buf) {
  	uint8_t string[10]; //Uint32 has maximum 10 digits
  	uint8_t length=0;
  	do {
  		string[length++] = getAsciiDigit(i % 10);
  		i /= 10;
  	} while(i != 0);
  	for(i=0; i<length; i++) {
      *next_byte = string[length-1-i];
  	  next_byte++;
  	}
  }
  
  void sendNext() {
  	PrintfMsg* m = (PrintfMsg*)call Packet.getPayload(&printfMsg, NULL);
  	length_to_send = (bytes_left_to_flush < TOSH_DATA_LENGTH) ? bytes_left_to_flush : TOSH_DATA_LENGTH;
  	memset(m->buffer, 0, sizeof(printfMsg));
  	memcpy((uint8_t*)next_byte, m->buffer, length_to_send);
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, TOSH_DATA_LENGTH) != SUCCESS)
      post retrySend();  
    else {
      bytes_left_to_flush -= length_to_send;
      next_byte += length_to_send;
    }
  }

  command error_t PrintfControl.start() {
  	if(state == S_STOPPED)
      return call SerialControl.start();
    return FAIL;
  }
  
  command error_t PrintfControl.stop() {
  	if(state == S_STARTED)
      return call SerialControl.stop();
    return FAIL;
  }

  event void SerialControl.startDone(error_t error) {
  	if(error != SUCCESS) {
  	  signal PrintfControl.startDone(error);
  	  return;
  	}
    atomic {
      memset(buffer, 0, sizeof(buffer));
      next_byte = buffer;
      bytes_left_to_flush = 0; 
      length_to_send = 0;
      state = S_STARTED;
    }
    signal PrintfControl.startDone(error); 
  }

  event void SerialControl.stopDone(error_t error) {
  	if(error != SUCCESS) {
  	  signal PrintfControl.stopDone(error);
  	  return;
  	}
    atomic state = S_STOPPED;
    signal PrintfControl.startDone(error); 
  }
  
  async command error_t Printf.printString(const char var[]) {
  	uint8_t var_length = 0;
  	while(var[var_length++] != '\0');
  	atomic {
  	  if(state == S_STARTED && (next_byte-buffer+var_length) < max_buffer_size) {
  	    memcpy((uint8_t*)var, next_byte, var_length);
  	    next_byte += var_length;
  	    return SUCCESS;
  	  }
  	  else return FAIL;
  	}
  }
  
  async command error_t Printf.printUint8(uint8_t var) {
  	atomic {                                         //Uint8 has maximum 3 digits
  	  if(state == S_STARTED && (next_byte-buffer+3) < max_buffer_size) {
  	    uint8_to_string(var, next_byte);
  	    return SUCCESS;
  	  }
  	  else return FAIL;
  	}
  }
  
  async command error_t Printf.printUint16(uint16_t var) {
  	atomic {                                         //Uint8 has maximum 5 digits
  	  if(state == S_STARTED && (next_byte-buffer+5) < max_buffer_size) {
  	    uint16_to_string(var, next_byte);
  	    return SUCCESS;
      }
  	  else return FAIL;
  	}
  }
  
  async command error_t Printf.printUint32(uint32_t var) {
  	atomic {                                         //Uint32 has maximum 10 digits
  	  if(state == S_STARTED && (next_byte-buffer+10) < max_buffer_size) {
  	    uint32_to_string(var, next_byte);
  	    return SUCCESS;
  	  }
  	  else return FAIL;
  	}
  }
  
  command error_t Printf.flush() {
  	atomic {
  	  if(state == S_STARTED && (next_byte > buffer)) {
  	    state = S_FLUSHING;
        bytes_left_to_flush = next_byte - buffer;
  	    next_byte = buffer;
  	  }
  	  else return FAIL;
  	}
  	sendNext();
  	return SUCCESS;
  }
    
  event void AMSend.sendDone(message_t* msg, error_t error) {
  	if(error == SUCCESS) {
  	  if(bytes_left_to_flush > 0)
  	    sendNext();
  	  else {
        next_byte = buffer;
        bytes_left_to_flush = 0; 
    	length_to_send = 0;
        atomic state = S_STARTED;
	    signal Printf.flushDone(error);
	  }
	}
	else post retrySend();
  }
}
