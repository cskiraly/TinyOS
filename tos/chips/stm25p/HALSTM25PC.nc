// $Id: HALSTM25PC.nc,v 1.1.2.2 2005-03-19 20:59:15 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes crc;
includes HALSTM25P;

configuration HALSTM25PC {
  provides {
    interface StdControl;
    interface HALSTM25P[volume_t volume];
  }
  uses {
    interface StorageRemap[volume_t volume];
  }
}

implementation {
  components HALSTM25PM, HPLSTM25PC, NoLedsC as Leds;

  StdControl = HALSTM25PM;
  StdControl = HPLSTM25PC;
  HALSTM25P = HALSTM25PM;
  StorageRemap = HALSTM25PM;

  HALSTM25PM.HPLSTM25P -> HPLSTM25PC;
  HALSTM25PM.Leds -> Leds;
}
