/// $Id: HplAtm128I2CBus.nc,v 1.1.2.2 2006-05-01 21:50:50 scipio Exp $

/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
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
 */

#include "Atm128I2C.h"

/**
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Philip Levis
 *
 * @version  $Id: HplAtm128I2CBus.nc,v 1.1.2.2 2006-05-01 21:50:50 scipio Exp $
 */
interface HplAtm128I2CBus {

  async command void init(bool hasExternalPulldown);
  async command void off();
  
  async command uint8_t status();
  
  // Transaction interface
  async command void start();   //!< Start bus transaction (send start symbol)
  async command bool isStarting();
  async command void clearStart();
  
  async command void stop();    //!< End bus transaction
  async command bool isStopping();

  // Data interface
  async command void write(uint8_t data);
  async command uint8_t read();

  async command void enableAck(bool enable);
  async command bool isAckEnabled();
  async command void enableInterrupt(bool enable);
  async command bool isInterruptEnabled();
  async command bool isInterruptPending();
  async command void clearInterruptPending();
  
  async event void symbolSent();
  
  async command void enable(bool enable);
  async command bool isEnabled();

  async command bool hasWriteCollided();

}
