
module MathOpsM
{
  provides interface MathOps<int8_t> as MathI8;
  provides interface MathOps<int16_t> as MathI16;
  provides interface MathOps<int32_t> as MathI32;
  provides interface MathOps<uint8_t> as MathU8;
  provides interface MathOps<uint16_t> as MathU16;
  provides interface MathOps<uint32_t> as MathU32;
}
implementation
{
  async command uint8_t MathI8.castToU8( int8_t a ) { return a; }
  async command int8_t MathI8.castToI8( int8_t a ) { return a; }
  async command uint32_t MathI8.castToU32( int8_t a ) { return a; }
  async command int32_t MathI8.castToI32( int8_t a ) { return a; }
  async command int8_t MathI8.castFromU8( uint8_t a ) { return a; }
  async command int8_t MathI8.castFromI8( int8_t a ) { return a; }
  async command int8_t MathI8.castFromU32( uint32_t a ) { return a; }
  async command int8_t MathI8.castFromI32( int32_t a ) { return a; }
  async command int8_t MathI8.inc( int8_t a ) { return a+1; }
  async command int8_t MathI8.dec( int8_t a ) { return a-1; }
  async command int8_t MathI8.add( int8_t a, int8_t b ) { return a+b; }
  async command int8_t MathI8.sub( int8_t a, int8_t b ) { return a-b; }
  async command int8_t MathI8.not( int8_t a ) { return ~a; }
  async command int8_t MathI8.and( int8_t a, int8_t b ) { return a & b; }
  async command int8_t MathI8.or( int8_t a, int8_t b ) { return a | b; }
  async command int8_t MathI8.xor( int8_t a, int8_t b ) { return a ^ b; }
  async command int8_t MathI8.sl( int8_t a, uint8_t n ) { return a << n; }
  async command int8_t MathI8.sr( int8_t a, uint8_t n ) { return a >> n; }
  async command bool MathI8.eq( int8_t a, int8_t b ) { return a == b; }
  async command bool MathI8.ne( int8_t a, int8_t b ) { return a != b; }
  async command bool MathI8.lt( int8_t a, int8_t b ) { return a < b; }
  async command bool MathI8.gt( int8_t a, int8_t b ) { return a > b; }
  async command bool MathI8.le( int8_t a, int8_t b ) { return a <= b; }
  async command bool MathI8.ge( int8_t a, int8_t b ) { return a >= b; }

  async command uint8_t MathI16.castToU8( int16_t a ) { return a; }
  async command int8_t MathI16.castToI8( int16_t a ) { return a; }
  async command uint32_t MathI16.castToU32( int16_t a ) { return a; }
  async command int32_t MathI16.castToI32( int16_t a ) { return a; }
  async command int16_t MathI16.castFromU8( uint8_t a ) { return a; }
  async command int16_t MathI16.castFromI8( int8_t a ) { return a; }
  async command int16_t MathI16.castFromU32( uint32_t a ) { return a; }
  async command int16_t MathI16.castFromI32( int32_t a ) { return a; }
  async command int16_t MathI16.inc( int16_t a ) { return a+1; }
  async command int16_t MathI16.dec( int16_t a ) { return a-1; }
  async command int16_t MathI16.add( int16_t a, int16_t b ) { return a+b; }
  async command int16_t MathI16.sub( int16_t a, int16_t b ) { return a-b; }
  async command int16_t MathI16.not( int16_t a ) { return ~a; }
  async command int16_t MathI16.and( int16_t a, int16_t b ) { return a & b; }
  async command int16_t MathI16.or( int16_t a, int16_t b ) { return a | b; }
  async command int16_t MathI16.xor( int16_t a, int16_t b ) { return a ^ b; }
  async command int16_t MathI16.sl( int16_t a, uint8_t n ) { return a << n; }
  async command int16_t MathI16.sr( int16_t a, uint8_t n ) { return a >> n; }
  async command bool MathI16.eq( int16_t a, int16_t b ) { return a == b; }
  async command bool MathI16.ne( int16_t a, int16_t b ) { return a != b; }
  async command bool MathI16.lt( int16_t a, int16_t b ) { return a < b; }
  async command bool MathI16.gt( int16_t a, int16_t b ) { return a > b; }
  async command bool MathI16.le( int16_t a, int16_t b ) { return a <= b; }
  async command bool MathI16.ge( int16_t a, int16_t b ) { return a >= b; }

  async command uint8_t MathI32.castToU8( int32_t a ) { return a; }
  async command int8_t MathI32.castToI8( int32_t a ) { return a; }
  async command uint32_t MathI32.castToU32( int32_t a ) { return a; }
  async command int32_t MathI32.castToI32( int32_t a ) { return a; }
  async command int32_t MathI32.castFromU8( uint8_t a ) { return a; }
  async command int32_t MathI32.castFromI8( int8_t a ) { return a; }
  async command int32_t MathI32.castFromU32( uint32_t a ) { return a; }
  async command int32_t MathI32.castFromI32( int32_t a ) { return a; }
  async command int32_t MathI32.inc( int32_t a ) { return a+1; }
  async command int32_t MathI32.dec( int32_t a ) { return a-1; }
  async command int32_t MathI32.add( int32_t a, int32_t b ) { return a+b; }
  async command int32_t MathI32.sub( int32_t a, int32_t b ) { return a-b; }
  async command int32_t MathI32.not( int32_t a ) { return ~a; }
  async command int32_t MathI32.and( int32_t a, int32_t b ) { return a & b; }
  async command int32_t MathI32.or( int32_t a, int32_t b ) { return a | b; }
  async command int32_t MathI32.xor( int32_t a, int32_t b ) { return a ^ b; }
  async command int32_t MathI32.sl( int32_t a, uint8_t n ) { return a << n; }
  async command int32_t MathI32.sr( int32_t a, uint8_t n ) { return a >> n; }
  async command bool MathI32.eq( int32_t a, int32_t b ) { return a == b; }
  async command bool MathI32.ne( int32_t a, int32_t b ) { return a != b; }
  async command bool MathI32.lt( int32_t a, int32_t b ) { return a < b; }
  async command bool MathI32.gt( int32_t a, int32_t b ) { return a > b; }
  async command bool MathI32.le( int32_t a, int32_t b ) { return a <= b; }
  async command bool MathI32.ge( int32_t a, int32_t b ) { return a >= b; }

  async command uint8_t MathU8.castToU8( uint8_t a ) { return a; }
  async command int8_t MathU8.castToI8( uint8_t a ) { return a; }
  async command uint32_t MathU8.castToU32( uint8_t a ) { return a; }
  async command int32_t MathU8.castToI32( uint8_t a ) { return a; }
  async command uint8_t MathU8.castFromU8( uint8_t a ) { return a; }
  async command uint8_t MathU8.castFromI8( int8_t a ) { return a; }
  async command uint8_t MathU8.castFromU32( uint32_t a ) { return a; }
  async command uint8_t MathU8.castFromI32( int32_t a ) { return a; }
  async command uint8_t MathU8.inc( uint8_t a ) { return a+1; }
  async command uint8_t MathU8.dec( uint8_t a ) { return a-1; }
  async command uint8_t MathU8.add( uint8_t a, uint8_t b ) { return a+b; }
  async command uint8_t MathU8.sub( uint8_t a, uint8_t b ) { return a-b; }
  async command uint8_t MathU8.not( uint8_t a ) { return ~a; }
  async command uint8_t MathU8.and( uint8_t a, uint8_t b ) { return a & b; }
  async command uint8_t MathU8.or( uint8_t a, uint8_t b ) { return a | b; }
  async command uint8_t MathU8.xor( uint8_t a, uint8_t b ) { return a ^ b; }
  async command uint8_t MathU8.sl( uint8_t a, uint8_t n ) { return a << n; }
  async command uint8_t MathU8.sr( uint8_t a, uint8_t n ) { return a >> n; }
  async command bool MathU8.eq( uint8_t a, uint8_t b ) { return a == b; }
  async command bool MathU8.ne( uint8_t a, uint8_t b ) { return a != b; }
  async command bool MathU8.lt( uint8_t a, uint8_t b ) { return a < b; }
  async command bool MathU8.gt( uint8_t a, uint8_t b ) { return a > b; }
  async command bool MathU8.le( uint8_t a, uint8_t b ) { return a <= b; }
  async command bool MathU8.ge( uint8_t a, uint8_t b ) { return a >= b; }

  async command uint8_t MathU16.castToU8( uint16_t a ) { return a; }
  async command int8_t MathU16.castToI8( uint16_t a ) { return a; }
  async command uint32_t MathU16.castToU32( uint16_t a ) { return a; }
  async command int32_t MathU16.castToI32( uint16_t a ) { return a; }
  async command uint16_t MathU16.castFromU8( uint8_t a ) { return a; }
  async command uint16_t MathU16.castFromI8( int8_t a ) { return a; }
  async command uint16_t MathU16.castFromU32( uint32_t a ) { return a; }
  async command uint16_t MathU16.castFromI32( int32_t a ) { return a; }
  async command uint16_t MathU16.inc( uint16_t a ) { return a+1; }
  async command uint16_t MathU16.dec( uint16_t a ) { return a-1; }
  async command uint16_t MathU16.add( uint16_t a, uint16_t b ) { return a+b; }
  async command uint16_t MathU16.sub( uint16_t a, uint16_t b ) { return a-b; }
  async command uint16_t MathU16.not( uint16_t a ) { return ~a; }
  async command uint16_t MathU16.and( uint16_t a, uint16_t b ) { return a & b; }
  async command uint16_t MathU16.or( uint16_t a, uint16_t b ) { return a | b; }
  async command uint16_t MathU16.xor( uint16_t a, uint16_t b ) { return a ^ b; }
  async command uint16_t MathU16.sl( uint16_t a, uint8_t n ) { return a << n; }
  async command uint16_t MathU16.sr( uint16_t a, uint8_t n ) { return a >> n; }
  async command bool MathU16.eq( uint16_t a, uint16_t b ) { return a == b; }
  async command bool MathU16.ne( uint16_t a, uint16_t b ) { return a != b; }
  async command bool MathU16.lt( uint16_t a, uint16_t b ) { return a < b; }
  async command bool MathU16.gt( uint16_t a, uint16_t b ) { return a > b; }
  async command bool MathU16.le( uint16_t a, uint16_t b ) { return a <= b; }
  async command bool MathU16.ge( uint16_t a, uint16_t b ) { return a >= b; }

  async command uint8_t MathU32.castToU8( uint32_t a ) { return a; }
  async command int8_t MathU32.castToI8( uint32_t a ) { return a; }
  async command uint32_t MathU32.castToU32( uint32_t a ) { return a; }
  async command int32_t MathU32.castToI32( uint32_t a ) { return a; }
  async command uint32_t MathU32.castFromU8( uint8_t a ) { return a; }
  async command uint32_t MathU32.castFromI8( int8_t a ) { return a; }
  async command uint32_t MathU32.castFromU32( uint32_t a ) { return a; }
  async command uint32_t MathU32.castFromI32( int32_t a ) { return a; }
  async command uint32_t MathU32.inc( uint32_t a ) { return a+1; }
  async command uint32_t MathU32.dec( uint32_t a ) { return a-1; }
  async command uint32_t MathU32.add( uint32_t a, uint32_t b ) { return a+b; }
  async command uint32_t MathU32.sub( uint32_t a, uint32_t b ) { return a-b; }
  async command uint32_t MathU32.not( uint32_t a ) { return ~a; }
  async command uint32_t MathU32.and( uint32_t a, uint32_t b ) { return a & b; }
  async command uint32_t MathU32.or( uint32_t a, uint32_t b ) { return a | b; }
  async command uint32_t MathU32.xor( uint32_t a, uint32_t b ) { return a ^ b; }
  async command uint32_t MathU32.sl( uint32_t a, uint8_t n ) { return a << n; }
  async command uint32_t MathU32.sr( uint32_t a, uint8_t n ) { return a >> n; }
  async command bool MathU32.eq( uint32_t a, uint32_t b ) { return a == b; }
  async command bool MathU32.ne( uint32_t a, uint32_t b ) { return a != b; }
  async command bool MathU32.lt( uint32_t a, uint32_t b ) { return a < b; }
  async command bool MathU32.gt( uint32_t a, uint32_t b ) { return a > b; }
  async command bool MathU32.le( uint32_t a, uint32_t b ) { return a <= b; }
  async command bool MathU32.ge( uint32_t a, uint32_t b ) { return a >= b; }


}

