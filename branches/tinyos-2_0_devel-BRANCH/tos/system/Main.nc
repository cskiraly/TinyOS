
configuration Main
{
  provides interface Boot;
  uses interface Init as SoftwareInit;
}
implementation
{
  components Platform, RealMain, TinyScheduler;

  RealMain.Scheduler -> TinyScheduler;
  RealMain.PlatformInit -> Platform;

  // Export the SoftwareInit and Booted for applications
  SoftwareInit = RealMain.SoftwareInit;
  Boot = RealMain;
}

