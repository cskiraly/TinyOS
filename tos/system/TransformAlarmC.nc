//$Id: TransformAlarmC.nc,v 1.1.2.1 2005-02-26 03:23:57 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

// The TinyOS Timer interfaces are discussed in TEP 102.

generic configuration TransformAlarmC( 
  typedef to_frequency_tag,
  typedef to_size_type,
  typedef from_frequency_tag,
  typedef from_size_type,
  uint8_t bit_shift_right )
{
  provides interface AlarmBase<to_size_type,to_frequency_tag> as Alarm;
  uses interface CounterBase<to_size_type,to_frequency_tag> as Counter;
  uses interface AlarmBase<from_size_type,from_frequency_tag> as AlarmFrom;
}
implementation
{
  components new TransformAlarmM( to_frequency_tag, to_size_type,
    from_frequency_tag, from_size_type, bit_shift_right) as XformAlarmM
           , MathOpsM
           , CastOpsM
           ;

  Alarm = XformAlarmM;
  Counter = XformAlarmM;
  AlarmFrom = XformAlarmM;

  XformAlarmM.MathTo -> MathOpsM;
  XformAlarmM.MathFrom -> MathOpsM;
  XformAlarmM.CastFromTo -> CastOpsM;
}

