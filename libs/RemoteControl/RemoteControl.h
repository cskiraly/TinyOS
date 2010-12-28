/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Ported to T2: Brano Kusy
 */
#ifndef REMOTECONTROL_H
#define REMOTECONTROL_H

enum
{
    AM_CONTROL_MSG= 0x4E,
    AM_CONTROL_ACK = 0x4F
};
enum
{
  INIT_SEQ = 0,
  UNDEFINED_SEQ = 0x80
};

typedef nx_struct control_msg
{
    nx_uint8_t seqNum;     // sequence number (incremeneted at the base station)
    nx_uint16_t target;    // node id of final destination, or 0xFFFF for all, or 0xFF?? or a group of nodes
    nx_uint8_t dataType;   // what kind of command is this
    nx_uint8_t appId;      // app id of final destination
    nx_uint8_t data[0];    // variable length data packet
} control_msg_t; // "__attribute__ ((packed))" to make it work on PC


typedef nx_struct control_ack
{
    nx_uint16_t nodeId;
    nx_uint8_t seqNum;
    nx_uint32_t ret;
} control_ack_t;

#endif
