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
 * @version $Revision: 1.1.2.2 $
 * @date $Date: 2006-05-22 22:38:36 $
 */
 
generic module AsyncRoundRobinQueueC(uint8_t size) {
  provides {
    interface Init;
    interface AsyncQueue<uint8_t> as RoundRobinQueue;
  }
}
implementation {
  enum {NO_ENTRY = 0xFF};

  uint8_t resQ[(size-1)/8 + 1];
  uint8_t last = 0;
  uint8_t current_size;
  
  bool inQueue(uint8_t id) {
    return resQ[id / 8] & (1 << (id % 8));
  }

  void clearEntry(uint8_t id) {
    resQ[id / 8] &= ~(1 << (id % 8));
  }

  command error_t Init.init() {
    memset(resQ, NO_ENTRY, sizeof(resQ));
    current_size = 0;
    return SUCCESS;
  }  

  async command uint8_t RoundRobinQueue.dequeue() {
    int i;
    atomic {
      for (i = last+1; ; i++) {
        if(i == size)
          i = 0;
        if (i == last)
          break;
        if (inQueue(i)) {
          clearEntry(i);
          last = i;
          current_size--;
          return i;
        }
      }
      return NO_ENTRY;
    }
  }
  
  async command error_t RoundRobinQueue.enqueue(uint8_t id) {
    atomic {
      if (!inQueue(id)) {
        resQ[id / 8] |=  1 << (id % 8);
        current_size++;
        return SUCCESS;
      }
      return EBUSY;
    }
  }

  async command bool RoundRobinQueue.empty() {
    int i;
    atomic {
      for (i = 0; i<sizeof(resQ); i++)
        if(resQ[i] > 0) return FALSE;
      return TRUE;
    }
  }

  async command uint8_t RoundRobinQueue.size() {
    atomic return current_size;
  }
  
  async command uint8_t RoundRobinQueue.maxSize() {
    atomic return size;
  }
  
  async command uint8_t RoundRobinQueue.head() {
    int i;
    atomic {
      for (i = last+1; ; i++) {
        if(i == size)
          i = 0;
        if (i == last)
          break;
        if (inQueue(i))
          return i;
      }
      return NO_ENTRY;
    }
  }
}
