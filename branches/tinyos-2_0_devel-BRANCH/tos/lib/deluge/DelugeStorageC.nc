// $Id: DelugeStorageC.nc,v 1.1.2.1 2005-06-07 20:20:49 jwhui Exp $

/*									tab:4
 *
 *
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

configuration DelugeStorageC {
  provides {
    interface DelugeDataRead as DataRead[uint8_t id];
    interface DelugeDataWrite as DataWrite[uint8_t id];
    interface DelugeStorage;
  }
}
implementation {

  components
    Main,
    DelugeStorageM as Storage,
    new BlockStorageC() as BlockStorage0,
    new BlockStorageC() as BlockStorage1,
    new BlockStorageC() as BlockStorage2,
    LedsC as Leds;

  DataRead = Storage;
  DataWrite = Storage;
  DelugeStorage = Storage;

  Main.StdControl -> Storage;

  Storage.Leds -> Leds;

  Storage.BlockRead[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.BlockWrite[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.Mount[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.StorageRemap[DELUGE_VOLUME_ID_0] -> BlockStorage0;

  Storage.BlockRead[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.BlockWrite[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.Mount[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.StorageRemap[DELUGE_VOLUME_ID_1] -> BlockStorage1;

  Storage.BlockRead[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.BlockWrite[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.Mount[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.StorageRemap[DELUGE_VOLUME_ID_2] -> BlockStorage2;

}
