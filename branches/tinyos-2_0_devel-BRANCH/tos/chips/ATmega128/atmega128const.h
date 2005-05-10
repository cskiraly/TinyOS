#ifndef ATMEGA128CONST_H
#define ATMEGA128CONST_H

typedef uint8_t const_uint8_t PROGMEM;
typedef uint16_t const_uint16_t PROGMEM;
typedef uint32_t const_uint32_t PROGMEM;
typedef int8_t const_int8_t PROGMEM;
typedef int16_t const_int16_t PROGMEM;
typedef int32_t const_int32_t PROGMEM;

#define read_uint8_t(x) pgm_read_byte(x)
#define read_uint16_t(x) pgm_read_word(x)
#define read_uint32_t(x) pgm_read_dword(x)

#define read_int8_t(x) ((int8_t)pgm_read_byte(x))
#define read_int16_t(x) ((int16_t)pgm_read_word(x))
#define read_int32_t(x) ((int32_t)pgm_read_dword(x))


#endif
