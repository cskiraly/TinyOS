interface SimMote {
  command long long euid();
  command void setEuid(long long euid);
  command long long startTime();
  command bool isOn();
  command void turnOn();
  command void turnOff();
}
