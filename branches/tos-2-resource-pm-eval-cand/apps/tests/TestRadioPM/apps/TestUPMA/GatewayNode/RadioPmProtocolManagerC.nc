/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-05-15 19:36:08 $
 */

#include "PEAS.h"
#include "AppDutyCycles.h"

configuration RadioPmProtocolManagerC {}
implementation {
  components ActiveMessageC;
  components new PeasC(PEAS_ON_TIME, PEAS_OFF_TIME, AM_PEAS_PROBE, AM_PEAS_REPLY);
//   components new ReceivingAppC(APP0_ON_TIME, APP0_OFF_TIME, AM_APP_0) as ReceivingApp0;
//   components new ReceivingAppC(APP1_ON_TIME, APP1_OFF_TIME, AM_APP_1) as ReceivingApp1;
//   components new ReceivingAppC(APP2_ON_TIME, APP2_OFF_TIME, AM_APP_2) as ReceivingApp2;
//   components new ReceivingAppC(APP3_ON_TIME, APP3_OFF_TIME, AM_APP_3) as ReceivingApp3;
//   components new ReceivingAppC(APP4_ON_TIME, APP4_OFF_TIME, AM_APP_4) as ReceivingApp4;
  components new ReceivingAppC(APP5_ON_TIME, APP5_OFF_TIME, AM_APP_5) as ReceivingApp5;
}

