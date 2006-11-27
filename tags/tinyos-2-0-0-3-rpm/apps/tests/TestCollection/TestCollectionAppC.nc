/**
 * TestCollectionAppC exercises collection.
 *
 * 
 * @author Kyle Jamieson
 * @version $Id: TestCollectionAppC.nc,v 1.1.2.1 2006-05-16 17:48:21 kasj78 Exp $
 * @see Net2-WG
 */

configuration TestCollectionAppC {}
implementation {
  components TestCollectionC, MainC, LedsC;

  TestCollectionC.Boot -> MainC;
  TestCollectionC.Leds -> LedsC;

  components new CollectionSenderC(0xDE);

  components new TimerMilliC();
  TestCollectionC.Timer -> TimerMilliC;
}
