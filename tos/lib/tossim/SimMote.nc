interface SimMote {
  command long long int getEuid();
  command void setEuid(long long int euid);
  command long long int getStartTime();
  command bool isOn();
  command void turnOn();
  command void turnOff();
}
