//$Id: TransformAlarmC.nc,v 1.1.2.2 2005-04-01 08:30:56 cssharp Exp $

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

// TransformAlarmC increases the size and/or decreases the frequency of an
// existing Alarm.  It knows how to change the size just given the From and To
// size types, and will apply bit_shift_right to decrease the frequency by a
// power of two.

generic configuration TransformAlarmC( 
  typedef to_frequency_tag,
  typedef to_size_type @integer(),
  typedef from_frequency_tag,
  typedef from_size_type, @integer()
  uint8_t bit_shift_right )
{
  provides interface AlarmBase<to_frequency_tag,to_size_type> as Alarm;
  uses interface CounterBase<to_frequency_tag,to_size_type> as Counter;
  uses interface AlarmBase<from_frequency_tag,from_size_type> as AlarmFrom;
}
implementation
{
  components new TransformAlarmM( to_frequency_tag, to_size_type,
    from_frequency_tag, from_size_type, bit_shift_right ) as Transform
           ;

  Alarm = Transform;
  Counter = Transform;
  AlarmFrom = Transform;
}

