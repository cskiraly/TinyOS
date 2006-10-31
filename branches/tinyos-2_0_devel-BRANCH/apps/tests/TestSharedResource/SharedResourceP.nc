/*
 * "Copyright (c) 2006 Washington University in St. Louis.
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
 * @date $Date: 2006-10-31 08:44:21 $
 */
 
#define TEST_SHARED_RESOURCE   "Test.Shared.Resource"
configuration SharedResourceP {
	provides interface Resource[uint8_t id];
	provides interface ResourceRequested[uint8_t id];
	provides interface ResourceOperations[uint8_t id];
	uses interface ResourceConfigure[uint8_t id];
}
implementation {
  components new RoundRobinArbiterC(TEST_SHARED_RESOURCE) as Arbiter;
  components new SplitControlPowerManagerC() as PowerManager;
  components ResourceP;
  components SharedResourceImplP;

  ResourceOperations = SharedResourceImplP;
  Resource = Arbiter;
  ResourceRequested = Arbiter;
  ResourceConfigure = Arbiter;
  SharedResourceImplP.ArbiterInfo -> Arbiter;
  PowerManager.ResourceController -> Arbiter;
  
  PowerManager.SplitControl -> ResourceP;
  SharedResourceImplP.ResourceOperations -> ResourceP;
}

