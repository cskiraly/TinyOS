/**
 *  Copyright (c) 2004-2006 Crossbow Technology, Inc.
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
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: HplI2CBusC.nc,v 1.1.2.2 2006-01-22 07:01:35 mturon Exp $
 */

/**
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @version    2005/9/11    mturon     Initial version
 */
configuration HplI2CBusC
{
    provides interface HplI2CBus as I2C;
}
implementation {

    components LedsC
    	, HplAtm128GeneralIOC
    	, BusyWaitMicroC
    	, HplI2CBusP
    	;
  
    I2C = HplI2CBusP.I2C;
    
    HplI2CBusP.Leds -> LedsC;
    HplI2CBusP.uWait -> BusyWaitMicroC;
    HplI2CBusP.I2CClk -> HplAtm128GeneralIOC.PortD0;
    HplI2CBusP.I2CData -> HplAtm128GeneralIOC.PortD1;
}
