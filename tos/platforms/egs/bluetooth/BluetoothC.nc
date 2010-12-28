configuration BluetoothC{
  provides interface Bluetooth;
}
implementation {
  components BluetoothP, LedsC;
  Bluetooth = BluetoothP;
  BluetoothP.Leds -> LedsC;

  components Sam3uUsart1C;
  BluetoothP.Usart -> Sam3uUsart1C;

  components LcdC;
  BluetoothP.Draw -> LcdC;

  components new TimerMilliC() as TimerC;
  BluetoothP.Timer -> TimerC;
}