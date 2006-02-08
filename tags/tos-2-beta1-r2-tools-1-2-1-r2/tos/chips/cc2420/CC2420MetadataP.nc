/*
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
 * @author Alec Woo <awoo@archedrock.com>
 * @version $Revision: 1.1.2.1 $ $Date: 2006-01-29 17:50:45 $
 */

module CC2420MetadataP{
  provides interface CC2420Metadata;
}

implementation{

  command uint8_t CC2420Metadata.linkQual(message_t* pMsg){
    uint8_t result;
    cc2420_metadata_t * mdata = (cc2420_metadata_t *) pMsg->metadata;

    // Assume range is 64 from 48 (lowest) to 112 (highest) 
    if(mdata->lqi <48) 
      result = 0;
    else if (mdata->lqi > 112)
      result = 255;
    else 
      // (lqi - 48)/64 * 256
      result = (mdata->lqi - 48) << 2; 

    return result;    
  }

  command int16_t CC2420Metadata.rssi(message_t* pMsg){
    cc2420_metadata_t * mdata = (cc2420_metadata_t *) pMsg->metadata;
    return ((int16_t) mdata->strength - (int16_t) 45); // do no scaling for now    
  }

}
