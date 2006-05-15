/* Copyright (C) 2004, Washington University in Saint Louis 
 * 
 * Washington University states that this is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * This software is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT THIS SOFTWARE IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using this code you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using this code. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

/*  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *  Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/**
 * CC1000 constants and structures for use with Csma using Squelch.
 *
 * <pre>
 *  $Id: CC1000CsmaConst.h,v 1.1.2.1 2006-05-15 19:46:04 klueska Exp $
 * </pre>
 *
 * @author Phil Buonadonna
 * @author Kevin Klues
 * @date   October 3 2005
 */

#ifndef CC1000CSMACONST_H
#define CC1000CSMACONST_H

enum {
//#define BMac_SquelchInit        0x02F8 // 0.90V using the bandgap reference
  CC1K_SquelchInit =        0x120,
  CC1K_SquelchTableSize =   9,
  CC1K_MaxRSSISamples =     5,
  CC1K_Settling =           1,
  CC1K_ValidPrecursor =     2,
  CC1K_SquelchIntervalFast = 128,
  CC1K_SquelchIntervalSlow = 2560,
  CC1K_SquelchCount =       30,
  CC1K_SquelchBuffer =      12
};

#endif //CC1000CSMACONST_H



