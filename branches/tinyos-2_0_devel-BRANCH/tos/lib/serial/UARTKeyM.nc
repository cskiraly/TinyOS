generic module UARTKeyM(uint8_t key) {
  provides interface Key<uint8_t>;
}
implementation {
  command uint8_t Key.get() {
    return key;
  } 
}
