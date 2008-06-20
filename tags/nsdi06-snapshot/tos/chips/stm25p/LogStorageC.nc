// $Id: LogStorageC.nc,v 1.1.2.1 2005-06-07 20:05:35 jwhui Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

includes LogStorage;

generic configuration LogStorageC() {
  provides {
    interface Mount;
    interface LogRead;
    interface LogWrite;
  }
}

implementation {

  enum {
    LOG_ID = unique("LogStorage"),
    VOLUME_ID = unique("StorageManager"),
  };

  components LogStorageM, Main, StorageManagerC, LedsC as Leds;

  Mount = LogStorageM.Mount[LOG_ID];
  LogRead = LogStorageM.LogRead[LOG_ID];
  LogWrite = LogStorageM.LogWrite[LOG_ID];

  Main.StdControl -> StorageManagerC;

  LogStorageM.SectorStorage[LOG_ID] -> StorageManagerC.SectorStorage[VOLUME_ID];
  LogStorageM.StorageManager[LOG_ID] -> StorageManagerC.StorageManager[VOLUME_ID];
  LogStorageM.ActualMount[LOG_ID] -> StorageManagerC.Mount[VOLUME_ID];
  LogStorageM.Leds -> Leds;
  
}