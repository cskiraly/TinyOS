// $Id: HPLGeneralIOC.nc,v 1.1.2.1 2005-03-17 14:42:29 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

configuration HPLGeneralIOC
{
  // provides all the ports as raw ports
  provides {
    interface GeneralIO as PortA0;
    interface GeneralIO as PortA1;
    interface GeneralIO as PortA2;
    interface GeneralIO as PortA3;
    interface GeneralIO as PortA4;
    interface GeneralIO as PortA5;
    interface GeneralIO as PortA6;
    interface GeneralIO as PortA7;

    interface GeneralIO as PortB0;
    interface GeneralIO as PortB1;
    interface GeneralIO as PortB2;
    interface GeneralIO as PortB3;
    interface GeneralIO as PortB4;
    interface GeneralIO as PortB5;
    interface GeneralIO as PortB6;
    interface GeneralIO as PortB7;

    interface GeneralIO as PortC0;
    interface GeneralIO as PortC1;
    interface GeneralIO as PortC2;
    interface GeneralIO as PortC3;
    interface GeneralIO as PortC4;
    interface GeneralIO as PortC5;
    interface GeneralIO as PortC6;
    interface GeneralIO as PortC7;

    interface GeneralIO as PortD0;
    interface GeneralIO as PortD1;
    interface GeneralIO as PortD2;
    interface GeneralIO as PortD3;
    interface GeneralIO as PortD4;
    interface GeneralIO as PortD5;
    interface GeneralIO as PortD6;
    interface GeneralIO as PortD7;

    interface GeneralIO as PortE0;
    interface GeneralIO as PortE1;
    interface GeneralIO as PortE2;
    interface GeneralIO as PortE3;
    interface GeneralIO as PortE4;
    interface GeneralIO as PortE5;
    interface GeneralIO as PortE6;
    interface GeneralIO as PortE7;

    interface GeneralIO as PortF0;
    interface GeneralIO as PortF1;
    interface GeneralIO as PortF2;
    interface GeneralIO as PortF3;
    interface GeneralIO as PortF4;
    interface GeneralIO as PortF5;
    interface GeneralIO as PortF6;
    interface GeneralIO as PortF7;

    interface GeneralIO as PortG0;
    interface GeneralIO as PortG1;
    interface GeneralIO as PortG2;
    interface GeneralIO as PortG3;
    interface GeneralIO as PortG4;
  }
}
implementation
{
  components 
    new HPLGeneralIOM(PORTA, DDRA, 0) as A0,
    new HPLGeneralIOM(PORTA, DDRA, 1) as A1,
    new HPLGeneralIOM(PORTA, DDRA, 2) as A2,
    new HPLGeneralIOM(PORTA, DDRA, 3) as A3,
    new HPLGeneralIOM(PORTA, DDRA, 4) as A4,
    new HPLGeneralIOM(PORTA, DDRA, 5) as A5,
    new HPLGeneralIOM(PORTA, DDRA, 6) as A6,
    new HPLGeneralIOM(PORTA, DDRA, 7) as A7,

    new HPLGeneralIOM(PORTB, DDRB, 0) as B0,
    new HPLGeneralIOM(PORTB, DDRB, 1) as B1,
    new HPLGeneralIOM(PORTB, DDRB, 2) as B2,
    new HPLGeneralIOM(PORTB, DDRB, 3) as B3,
    new HPLGeneralIOM(PORTB, DDRB, 4) as B4,
    new HPLGeneralIOM(PORTB, DDRB, 5) as B5,
    new HPLGeneralIOM(PORTB, DDRB, 6) as B6,
    new HPLGeneralIOM(PORTB, DDRB, 7) as B7,

    new HPLGeneralIOM(PORTC, DDRC, 0) as C0,
    new HPLGeneralIOM(PORTC, DDRC, 1) as C1,
    new HPLGeneralIOM(PORTC, DDRC, 2) as C2,
    new HPLGeneralIOM(PORTC, DDRC, 3) as C3,
    new HPLGeneralIOM(PORTC, DDRC, 4) as C4,
    new HPLGeneralIOM(PORTC, DDRC, 5) as C5,
    new HPLGeneralIOM(PORTC, DDRC, 6) as C6,
    new HPLGeneralIOM(PORTC, DDRC, 7) as C7,

    new HPLGeneralIOM(PORTD, DDRD, 0) as D0,
    new HPLGeneralIOM(PORTD, DDRD, 1) as D1,
    new HPLGeneralIOM(PORTD, DDRD, 2) as D2,
    new HPLGeneralIOM(PORTD, DDRD, 3) as D3,
    new HPLGeneralIOM(PORTD, DDRD, 4) as D4,
    new HPLGeneralIOM(PORTD, DDRD, 5) as D5,
    new HPLGeneralIOM(PORTD, DDRD, 6) as D6,
    new HPLGeneralIOM(PORTD, DDRD, 7) as D7,

    new HPLGeneralIOM(PORTE, DDRE, 0) as E0,
    new HPLGeneralIOM(PORTE, DDRE, 1) as E1,
    new HPLGeneralIOM(PORTE, DDRE, 2) as E2,
    new HPLGeneralIOM(PORTE, DDRE, 3) as E3,
    new HPLGeneralIOM(PORTE, DDRE, 4) as E4,
    new HPLGeneralIOM(PORTE, DDRE, 5) as E5,
    new HPLGeneralIOM(PORTE, DDRE, 6) as E6,
    new HPLGeneralIOM(PORTE, DDRE, 7) as E7,

    new HPLGeneralIOM(PORTF, DDRF, 0) as F0,
    new HPLGeneralIOM(PORTF, DDRF, 1) as F1,
    new HPLGeneralIOM(PORTF, DDRF, 2) as F2,
    new HPLGeneralIOM(PORTF, DDRF, 3) as F3,
    new HPLGeneralIOM(PORTF, DDRF, 4) as F4,
    new HPLGeneralIOM(PORTF, DDRF, 5) as F5,
    new HPLGeneralIOM(PORTF, DDRF, 6) as F6,
    new HPLGeneralIOM(PORTF, DDRF, 7) as F7,

    new HPLGeneralIOM(PORTG, DDRG, 0) as G0,
    new HPLGeneralIOM(PORTG, DDRG, 1) as G1,
    new HPLGeneralIOM(PORTG, DDRG, 2) as G2,
    new HPLGeneralIOM(PORTG, DDRG, 3) as G3,
    new HPLGeneralIOM(PORTG, DDRG, 4) as G4
    ;

  PortA0 = A0;
  PortA1 = A1;
  PortA2 = A2;
  PortA3 = A3;
  PortA4 = A4;
  PortA5 = A5;
  PortA6 = A6;
  PortA7 = A7;

  PortB0 = B0;
  PortB1 = B1;
  PortB2 = B2;
  PortB3 = B3;
  PortB4 = B4;
  PortB5 = B5;
  PortB6 = B6;
  PortB7 = B7;

  PortC0 = C0;
  PortC1 = C1;
  PortC2 = C2;
  PortC3 = C3;
  PortC4 = C4;
  PortC5 = C5;
  PortC6 = C6;
  PortC7 = C7;

  PortD0 = D0;
  PortD1 = D1;
  PortD2 = D2;
  PortD3 = D3;
  PortD4 = D4;
  PortD5 = D5;
  PortD6 = D6;
  PortD7 = D7;

  PortE0 = E0;
  PortE1 = E1;
  PortE2 = E2;
  PortE3 = E3;
  PortE4 = E4;
  PortE5 = E5;
  PortE6 = E6;
  PortE7 = E7;

  PortF0 = F0;
  PortF1 = F1;
  PortF2 = F2;
  PortF3 = F3;
  PortF4 = F4;
  PortF5 = F5;
  PortF6 = F6;
  PortF7 = F7;

  PortG0 = G0;
  PortG1 = G1;
  PortG2 = G2;
  PortG3 = G3;
  PortG4 = G4;

}

