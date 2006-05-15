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

module TimeSyncP {
  provides {
    interface SplitControl;
  }
  uses {
    interface AMSend as SyncSend;
    interface Receive as SyncReceive;
  }
}
implementation 
{
  message_t syncMsg;
  
  command error_t SplitControl.start() {
    if(TOS_NODE_ID == 0) {
      if(call SyncSend.send(AM_BROADCAST_ADDR, &syncMsg, 0) != SUCCESS) {
        return FAIL;
      }
    }
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    return SUCCESS;
  }

  event void SyncSend.sendDone(message_t* msg, error_t error) {
    if(msg == &syncMsg)
      signal SplitControl.startDone(SUCCESS);
  }

  event message_t* SyncReceive.receive(message_t* msg, void* payload, uint8_t len) {
    signal SplitControl.startDone(SUCCESS);
    return msg;
  }
}
