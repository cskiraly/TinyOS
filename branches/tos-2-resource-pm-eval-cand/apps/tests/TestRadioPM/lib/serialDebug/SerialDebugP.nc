/*
 * "Copyright (c) 2005 Washington University in St. Louis.
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
 * @date $Date: 2006-05-15 19:36:09 $ 
 */

#include "SerialDebugMsg.h"

module SerialDebugP {
  provides {
    interface Boot;
    interface SerialDebug;
  }
  uses {
    interface Boot as MainBoot;
    interface Leds;
    interface SplitControl as AMSerialControl;
    interface AMSend as AMSerialSend;
    interface Packet as SerialPacket;
  }
}
implementation {
  
  message_t serialMsg;
  bool busy = TRUE;

  void strcpy(const char* src, nx_uint8_t* dest, uint8_t length) {
    int i;
    for(i=0; i<length; i++)
      dest[i] = src[i];
  }

  error_t sendMsg() {
    busy = TRUE;
    if(call AMSerialSend.send(AM_BROADCAST_ADDR, &serialMsg, sizeof(SerialDebugMsg)) == SUCCESS)
      return SUCCESS;
    busy = FALSE;
    return FAIL;    
  }

  event void MainBoot.booted() {
    SerialDebugMsg* m = (SerialDebugMsg*)call SerialPacket.getPayload(&serialMsg, NULL);
    memset(m, 0, sizeof(SerialDebugMsg));
    call AMSerialControl.start();
  }

  event void AMSerialControl.startDone(error_t error) {
    busy = FALSE;
    signal Boot.booted();
  }

  event void AMSerialControl.stopDone(error_t error) {
  }
    
  event void AMSerialSend.sendDone(message_t* msg, error_t error) {
    SerialDebugMsg* m = (SerialDebugMsg*)call SerialPacket.getPayload(&serialMsg, NULL);
    memset(m, 0, sizeof(SerialDebugMsg));
    busy = FALSE;
    signal SerialDebug.flushDone(error);
  }

  command error_t SerialDebug.print(const char* var, uint32_t val) {
    SerialDebugMsg* m;
    if(busy == TRUE) return FAIL;
    m = (SerialDebugMsg*)call SerialPacket.getPayload(&serialMsg, NULL);
    if(m->num_vars == SERIAL_DEBUG_NUM_VARS) return FAIL;
    strcpy(var, m->vars[m->num_vars], SERIAL_DEBUG_VAR_SIZE);
    m->vals[m->num_vars++] = val;
    return SUCCESS;
  }

  command error_t SerialDebug.flush() {
    return sendMsg();
  }

  default event void Boot.booted() {
  }
}
