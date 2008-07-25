#undef SAFE_TINYOS

static void led_off_0 (void) {
    __asm__ volatile ("bis.b #16, &0x0031"); // telos
    __asm__ volatile ("bis.b #16, &0x0029"); // shimmer
}

static void led_off_1 (void)  { 
    __asm__ volatile ("bis.b #32, &0x0031"); // telos
    __asm__ volatile ("bis.b #32, &0x0029"); // shimmer
}

static void led_off_2 (void)  {
    __asm__ volatile ("bis.b #64, &0x0031"); // telos
    __asm__ volatile ("bis.b #64, &0x0029"); // shimmer
}

static void led_on_0 (void) { 
    __asm__ volatile ("bic.b #16, &0x0031"); // telos
    __asm__ volatile ("bic.b #16, &0x0029"); // shimmer
}

static void led_on_1 (void) { 
    __asm__ volatile ("bic.b #32, &0x0031"); // telos
    __asm__ volatile ("bic.b #32, &0x0029"); // shimmer
}

static void led_on_2 (void) { 
    __asm__ volatile ("bic.b #64, &0x0031"); // telos
    __asm__ volatile ("bic.b #64, &0x0029"); // shimmer
}

static void delay (int len) 
{
  volatile int x, y;
  for (x=0; x<len; x++) { 
    for (y=0; y<1000; y++) { }
  }
}

static void v_short_delay (void) { delay (10); }

static void short_delay (void) { delay (80); }

static void long_delay (void) { delay (800); }

static void flicker (void)
{
    int i;
    for (i=0; i<20; i++) {
	delay (20);
	led_off_0 ();
	led_off_1 ();
	led_off_2 ();
	delay (20);
	led_on_0 ();
	led_on_1 ();
	led_on_2 ();
    }
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
}

static void roll (void)
{
    int i;
    for (i=0; i<10; i++) {
	delay (30);
	led_on_0 ();
	led_off_2 ();
	delay (30);
	led_on_1 ();
	led_off_0 ();
	delay (30);
	led_on_2 ();
	led_off_1 ();
    }
    led_off_2 ();
}
	    
static void separator (void)
{
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
    short_delay ();
    led_on_0 ();
    led_on_1 ();
    led_on_2 ();
    v_short_delay ();
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
    short_delay ();
}

static void display_b4 (int c) 
{
  switch (c) {
  case 3:
    led_on_2 ();
  case 2:
    led_on_1 ();
  case 1:
    led_on_0 ();
  case 0:
    long_delay ();
    break;
  default:
    flicker ();
  }
  separator ();
}

static void display_int (const unsigned int x)
{
  int i = 14;
  do {
    display_b4 (0x3 & (x >> i));
    i -= 2;
  } while (i >= 0);
}

static void display_int_flid (const unsigned int x)
{
  roll ();
  display_int (x);
  roll ();
}

// Not sure how to do this in Telosb without looking it up
void deputy_fail_noreturn_fast (int flid)
{
  // disable interrupts
  // set LEDS to output

  while (1) {
    display_int_flid (flid);
  }

}

void deputy_fail_mayreturn(int flid)
{
    deputy_fail_noreturn_fast(flid);
}

void deputy_fail_noreturn(int flid)
{
    deputy_fail_noreturn_fast(flid);
}
