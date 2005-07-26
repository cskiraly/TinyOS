includes Serial;

configuration SerialC {
  provides {
    interface Init;
    interface Receive;
    interface Send;
  }
  uses {
    interface Leds;
  }
}
implementation {
  components SerialActiveMessageC;
  
  Init = SerialActiveMessageC;
  Leds = SerialActiveMessageC;

  Receive = SerialActiveMessageC;
  Send = SerialActiveMessageC;
}

