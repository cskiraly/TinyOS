/**
 * TestCollectionAppC exercises collection.
 *
 * 
 * @author Kyle Jamieson
 * @version $Id: TestCollectionAppC.nc,v 1.1.2.2 2006-11-07 23:14:51 scipio Exp $
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