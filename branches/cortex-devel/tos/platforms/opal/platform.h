/* platform_bootstrap() defined to initialize opal
 * such that when put to sleep it will draw the lowest
 * current possible.
 */
#define platform_bootstrap() \
  sam3uLowPowerConfigure()
