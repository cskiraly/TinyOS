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
 * Constants and structures for use with Radio Duty Cycling.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-05-15 19:36:09 $
 */

#ifndef DUTY_CYCLING_H
#define DUTY_CYCLING_H

enum {
  DUTY_CYCLE_MODES = 102,
  DUTY_CYCLE_STEP = 200,
};

typedef enum {
  DUTY_CYCLE_0_MS = 0,
  DUTY_CYCLE_200_MS = 1,
  DUTY_CYCLE_400_MS = 2,
  DUTY_CYCLE_600_MS = 3,
  DUTY_CYCLE_800_MS = 4,
  DUTY_CYCLE_1000_MS = 5,
  DUTY_CYCLE_1200_MS = 6,
  DUTY_CYCLE_1400_MS = 7,
  DUTY_CYCLE_1600_MS = 8,
  DUTY_CYCLE_1800_MS = 9,
  DUTY_CYCLE_2000_MS = 10,
  DUTY_CYCLE_2200_MS = 11,
  DUTY_CYCLE_2400_MS = 12,
  DUTY_CYCLE_2600_MS = 13,
  DUTY_CYCLE_2800_MS = 14,
  DUTY_CYCLE_3000_MS = 15,
  DUTY_CYCLE_3200_MS = 16,
  DUTY_CYCLE_3400_MS = 17,
  DUTY_CYCLE_3600_MS = 18,
  DUTY_CYCLE_3800_MS = 19,
  DUTY_CYCLE_4000_MS = 20,
  DUTY_CYCLE_4200_MS = 21,
  DUTY_CYCLE_4400_MS = 22,
  DUTY_CYCLE_4600_MS = 23,
  DUTY_CYCLE_4800_MS = 24,
  DUTY_CYCLE_5000_MS = 25,
  DUTY_CYCLE_5200_MS = 26,
  DUTY_CYCLE_5400_MS = 27,
  DUTY_CYCLE_5600_MS = 28,
  DUTY_CYCLE_5800_MS = 29,
  DUTY_CYCLE_6000_MS = 30,
  DUTY_CYCLE_6200_MS = 31,
  DUTY_CYCLE_6400_MS = 32,
  DUTY_CYCLE_6600_MS = 33,
  DUTY_CYCLE_6800_MS = 34,
  DUTY_CYCLE_7000_MS = 35,
  DUTY_CYCLE_7200_MS = 36,
  DUTY_CYCLE_7400_MS = 37,
  DUTY_CYCLE_7600_MS = 38,
  DUTY_CYCLE_7800_MS = 39,
  DUTY_CYCLE_8000_MS = 40,
  DUTY_CYCLE_8200_MS = 41,
  DUTY_CYCLE_8400_MS = 42,
  DUTY_CYCLE_8600_MS = 43,
  DUTY_CYCLE_8800_MS = 44,
  DUTY_CYCLE_9000_MS = 45,
  DUTY_CYCLE_9200_MS = 46,
  DUTY_CYCLE_9400_MS = 47,
  DUTY_CYCLE_9600_MS = 48,
  DUTY_CYCLE_9800_MS = 49,
  DUTY_CYCLE_10000_MS = 50,
  DUTY_CYCLE_10200_MS = 51,
  DUTY_CYCLE_10400_MS = 52,
  DUTY_CYCLE_10600_MS = 53,
  DUTY_CYCLE_10800_MS = 54,
  DUTY_CYCLE_11000_MS = 55,
  DUTY_CYCLE_11200_MS = 56,
  DUTY_CYCLE_11400_MS = 57,
  DUTY_CYCLE_11600_MS = 58,
  DUTY_CYCLE_11800_MS = 59,
  DUTY_CYCLE_12000_MS = 60,
  DUTY_CYCLE_12200_MS = 61,
  DUTY_CYCLE_12400_MS = 62,
  DUTY_CYCLE_12600_MS = 63,
  DUTY_CYCLE_12800_MS = 64,
  DUTY_CYCLE_13000_MS = 65,
  DUTY_CYCLE_13200_MS = 66,
  DUTY_CYCLE_13400_MS = 67,
  DUTY_CYCLE_13600_MS = 68,
  DUTY_CYCLE_13800_MS = 69,
  DUTY_CYCLE_14000_MS = 70,
  DUTY_CYCLE_14200_MS = 71,
  DUTY_CYCLE_14400_MS = 72,
  DUTY_CYCLE_14600_MS = 73,
  DUTY_CYCLE_14800_MS = 74,
  DUTY_CYCLE_15000_MS = 75,
  DUTY_CYCLE_15200_MS = 76,
  DUTY_CYCLE_15400_MS = 77,
  DUTY_CYCLE_15600_MS = 78,
  DUTY_CYCLE_15800_MS = 79,
  DUTY_CYCLE_16000_MS = 80,
  DUTY_CYCLE_16200_MS = 81,
  DUTY_CYCLE_16400_MS = 82,
  DUTY_CYCLE_16600_MS = 83,
  DUTY_CYCLE_16800_MS = 84,
  DUTY_CYCLE_17000_MS = 85,
  DUTY_CYCLE_17200_MS = 86,
  DUTY_CYCLE_17400_MS = 87,
  DUTY_CYCLE_17600_MS = 88,
  DUTY_CYCLE_17800_MS = 89,
  DUTY_CYCLE_18000_MS = 90,
  DUTY_CYCLE_18200_MS = 91,
  DUTY_CYCLE_18400_MS = 92,
  DUTY_CYCLE_18600_MS = 93,
  DUTY_CYCLE_18800_MS = 94,
  DUTY_CYCLE_19000_MS = 95,
  DUTY_CYCLE_19200_MS = 96,
  DUTY_CYCLE_19400_MS = 97,
  DUTY_CYCLE_19600_MS = 98,
  DUTY_CYCLE_19800_MS = 99,
  DUTY_CYCLE_20000_MS = 100,
  DUTY_CYCLE_20200_MS = 101,
  DUTY_CYCLE_20400_MS = 102,
  DUTY_CYCLE_20600_MS = 103,
  DUTY_CYCLE_20800_MS = 104,
  DUTY_CYCLE_21000_MS = 105,
  DUTY_CYCLE_21200_MS = 106,
  DUTY_CYCLE_21400_MS = 107,
  DUTY_CYCLE_21600_MS = 108,
  DUTY_CYCLE_21800_MS = 109,
  DUTY_CYCLE_22000_MS = 110,
  DUTY_CYCLE_22200_MS = 111,
  DUTY_CYCLE_22400_MS = 112,
  DUTY_CYCLE_22600_MS = 113,
  DUTY_CYCLE_22800_MS = 114,
  DUTY_CYCLE_23000_MS = 115,
  DUTY_CYCLE_23200_MS = 116,
  DUTY_CYCLE_23400_MS = 117,
  DUTY_CYCLE_23600_MS = 118,
  DUTY_CYCLE_23800_MS = 119,
  DUTY_CYCLE_24000_MS = 120,
  DUTY_CYCLE_24200_MS = 121,
  DUTY_CYCLE_24400_MS = 122,
  DUTY_CYCLE_24600_MS = 123,
  DUTY_CYCLE_24800_MS = 124,
  DUTY_CYCLE_25000_MS = 125,
  DUTY_CYCLE_ALWAYS = 126,
} DutyCycleModes;

#endif //DUTY_CYCLING_H