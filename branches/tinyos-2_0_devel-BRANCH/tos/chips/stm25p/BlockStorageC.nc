// $Id: BlockStorageC.nc,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

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

includes BlockStorage;

generic configuration BlockStorageC() {
  provides {
    interface Mount;
    interface BlockRead;
    interface BlockWrite;
    interface StorageRemap;
  }
}

implementation {

  enum {
    BLOCK_ID = unique("BlockStorage"),
    VOLUME_ID = unique("StorageManager"),
  };

  components BlockStorageM, Main, StorageManagerC;

  Mount = BlockStorageM.Mount[BLOCK_ID];
  BlockRead = BlockStorageM.BlockRead[BLOCK_ID];
  BlockWrite = BlockStorageM.BlockWrite[BLOCK_ID];
  StorageRemap = StorageManagerC.StorageRemap[VOLUME_ID];

  Main.StdControl -> StorageManagerC;

  BlockStorageM.HALSTM25P[BLOCK_ID] -> StorageManagerC.HALSTM25P[VOLUME_ID];
  BlockStorageM.ActualMount[BLOCK_ID] -> StorageManagerC.Mount[VOLUME_ID];

}
