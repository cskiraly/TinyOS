//$Id: AlarmC.nc,v 1.1.2.1 2005-01-24 10:07:16 cssharp Exp $

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

configuration AlarmC
{
  // alarms required by standard tinyos components
  provides interface Alarm<TMilli> as AlarmTimerMilli;
  provides interface Alarm<T32khz> as AlarmTimerAsync32khz;

  // extra alarms to be used by applications
  provides interface Alarm<T32khz> as Alarm32khz1;
  provides interface Alarm<T32khz> as Alarm32khz2;
  // ...

  provides interface Alarm<TMicro> as AlarmMicro1;
  provides interface Alarm<TMicro> as AlarmMicro2;
  // ...
}
implementation
{
  // TODO, I think there may exist a nice Generic Component to build an
  // alarm given a hardware resource (as for instance exposed in the
  // tinyos-1.x MSP430Timer abstraction.
}


