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

#ifndef PEAS_H
#define PEAS_H

#include "DutyCycling.h"

typedef struct {
	uint16_t x;
	uint16_t y;
} NodeLoc_t;

typedef nx_struct {
  nx_uint16_t nodeId;
  //nx_uint16_t x;
  //nx_uint16_t y;
} PEASProbeMsg;

typedef nx_struct {
  nx_uint16_t nodeId;
  //nx_uint16_t x;
  //nx_uint16_t y;
} PEASReplyMsg;

#define PEAS_ON_TIME  DUTY_CYCLE_200_MS
#define PEAS_OFF_TIME DUTY_CYCLE_15800_MS

enum {
	REPLY_DELAY = 60,
	ARBITRATION_TIME = 2000,
	MAX_NUM_PROBES = 3,
	INIT_SLEEP_TIME = 10000,
	AM_PEAS_PROBE = 6,
	AM_PEAS_REPLY = 7
};


typedef enum {
	SLEEPING = 0,
	INITING = 1,
	PROBING = 2,
	WORKING= 3
} NodeState_t;
#endif

