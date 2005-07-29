/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University  of California.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Joe Polastre
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: SPIC.nc,v 1.1.2.1 2005-07-29 05:35:58 mturon Exp $
 */

generic configuration SPIC() {
  provides interface Init;
  provides interface BusArbitration;
  provides interface SPIByte;
  provides interface SPIPacket;
  provides interface SPIPacketAdvanced;
}
implementation {
  components HalSpiMasterM as SpiMaster;

  enum {
    SPI_BUS_ID = unique("Bus.HPLSPI"),
  };

  Init = SpiMaster;
  SPIByte = SpiMaster.SPIByte[SPI_BUS_ID];
  SPIPacket = SpiMaster.SPIPacket[SPI_BUS_ID];
  SPIPacketAdvanced = SpiMaster.SPIPacketAdvanced[SPI_BUS_ID];
  BusArbitration = SpiMaster.BusArbitration[SPI_BUS_ID];
}
