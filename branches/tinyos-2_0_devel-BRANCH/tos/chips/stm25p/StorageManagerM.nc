// $Id: StorageManagerM.nc,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module StorageManagerM {
  provides {
    interface Mount[volume_t volume];
    interface StdControl;
    interface StorageRemap[volume_t volume];
  }
}

implementation {

  enum {
    NUM_VOLUMES = uniqueCount("StorageManager"),
  };

  uint8_t volumeMap[NUM_VOLUMES];
  volume_t curVolume;

  command result_t StdControl.init() {

    uint8_t i;

    curVolume = SM_INVALID_VOLUME;

    for ( i = 0; i < NUM_VOLUMES; i++ )
      volumeMap[i] = SM_INVALID_VOLUME;

    return SUCCESS; 

  }

  command result_t StdControl.start() { 
    return SUCCESS; 
  }

  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  void signalMounted() {
    volume_id_t tmpVolume = curVolume;
    curVolume = SM_INVALID_VOLUME;
    signal Mount.mountDone[tmpVolume](STORAGE_OK, volumeMap[tmpVolume]);
  }

  task void mounted() {
    signalMounted();
  }

  command result_t Mount.mount[volume_t volume](volume_id_t volumeID) {

    if (curVolume != SM_INVALID_VOLUME || volumeID >= SM_MAX_VOLUMES)
      return FAIL;

    curVolume = volume;
    volumeMap[volume] = volumeID;
    
    post mounted();
    
    return SUCCESS;

  }
  
  command uint32_t StorageRemap.physicalAddr[volume_t _volume](uint32_t volumeAddr) {
    
    uint32_t base = (uint32_t)volumeMap[_volume]*SM_VOLUME_SIZE;
    
    if (volumeMap[_volume] == SM_INVALID_VOLUME || volumeAddr >= SM_VOLUME_SIZE)
      return SM_INVALID_ADDR;
    
    return base + volumeAddr;
    
  }

  default event void Mount.mountDone[volume_t volume](storage_result_t result, volume_id_t id) { ; }

}
