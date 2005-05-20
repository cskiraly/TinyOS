/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 12:54:14 $ 
 * ======================================================================== 
 */
 
 /**
 * TDA5250RadioIO configuration
 * Configuration file for using the IO pins to the TDA5250 Radio on 
 * the eyesIFX platforms
 * 
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 */
configuration TDA5250RadioIO
{
  provides interface GeneralIO as TDA5250RadioBUSM;
  provides interface GeneralIO as TDA5250RadioENTDA;
  provides interface GeneralIO as TDA5250RadioTXRX;
  provides interface GeneralIO as TDA5250RadioDATA;
  provides interface GeneralIO as TDA5250RadioPWDDD;
}
implementation {
  components
      MSP430GeneralIOC as MSPGeneralIO
    , new GeneralIOM() as rBUSM
    , new GeneralIOM() as rENTDA
    , new GeneralIOM() as rTXRX
    , new GeneralIOM() as rDATA
    , new GeneralIOM() as rPWDD
    ;

  TDA5250RadioBUSM = rBUSM;
  TDA5250RadioENTDA = rENTDA;
  TDA5250RadioTXRX = rTXRX;
  TDA5250RadioDATA = rDATA;
  TDA5250RadioPWDDD = rPWDD;    
    
  rBUSM -> MSPGeneralIO.Port15;
  rENTDA -> MSPGeneralIO.Port16;
  rTXRX -> MSPGeneralIO.Port14;
  rDATA -> MSPGeneralIO.Port11;
  rPWDD -> MSPGeneralIO.Port10;
}

