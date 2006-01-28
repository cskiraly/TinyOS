/**
 * Copyright (c) 2005-2006 Arched Rock Corporation
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
 */

/**
 * Implementation of the block storage abstraction from TEP103 for the
 * ST M25P serial code flash.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.6 $ $Date: 2006-01-28 01:39:30 $
 */

includes Stm25p;

generic configuration BlockStorageC( volume_id_t volume_id ) {

  provides interface BlockRead;
  provides interface BlockWrite;
  provides interface StorageMap;

}

implementation {

  enum {
    BLOCK_ID = unique( "Stm25p.Block" ),
    VOLUME_ID = unique( "Stm25p.Volume" ),
  };

  components Stm25pBlockP as BlockP;
  components new Stm25pBinderP( volume_id ) as BinderP;
  components Stm25pSectorC as SectorC;
  
  BlockRead = BlockP.Read[ BLOCK_ID ];
  BlockWrite = BlockP.Write[ BLOCK_ID ];
  StorageMap = BlockP.StorageMap[ BLOCK_ID ];

  BlockP.ClientResource[ BLOCK_ID ] -> SectorC.ClientResource[ VOLUME_ID ];
  BlockP.Sector[ BLOCK_ID ] -> SectorC.Sector[ VOLUME_ID ];
  BinderP.Volume -> SectorC.Volume[ VOLUME_ID ];

  components LedsC;
  BlockP.Leds -> LedsC;

}

