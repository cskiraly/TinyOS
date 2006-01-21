#ifndef SCALE_H
#define SCALE_H

/* Multiply x by a/b while avoiding overflow when possible.
   Requires that a*b <= max value of from_t.
   Assumes unsigned arithmetic. */
inline uint32_t scale32(uint32_t x, uint32_t a, uint32_t b) 
{
  uint32_t x_over_b = x / b;
  uint32_t x_mod_b = x % b;

  x_mod_b *= a; // on a separate line just in case some compiler goes weird
  return x_over_b * a + x_mod_b / b;
}

#endif
