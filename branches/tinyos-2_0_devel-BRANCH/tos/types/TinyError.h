// $Id: TinyError.h,v 1.1.2.7 2005-02-10 01:29:50 scipio Exp $
/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * @author Phil Levis
 * Revision:  $Revision: 1.1.2.7 $
 *
 * Defines global error codes for error_t in TinyOS.
 */

typedef enum {
  SUCCESS        = 0,          
  FAIL           = 1,           // Generic condition: backwards compatible
  ESIZE          = 2,           // Parameter passed in was too big.
  ECANCEL        = 3,           // Operation cancelled by a call.
  EOFF           = 4,           // Subsystem is not active
  EBUSY          = 5,           // The posted task has already been posted
} error_t;

error_t rcombine(error_t r1, error_t r2)
/* Returns: FAIL if r1 or r2 == FAIL , r2 otherwise. This is the standard
     combining rule for results
*/
{
  return (r1 || r2)? SUCCESS:FAIL;
}

error_t rcombine3(error_t r1, error_t r2, error_t r3)
{
  return rcombine(r1, rcombine(r2, r3));
}

error_t rcombine4(error_t r1, error_t r2, error_t r3,
				 error_t r4)
{
  return rcombine(r1, rcombine(r2, rcombine(r3, r4)));
}
