
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
<perl>
  my $text =<<'EOF';
  async command uint8_t MathX.castToU8( type a ) { return a; }
  async command int8_t MathX.castToI8( type a ) { return a; }
  async command uint32_t MathX.castToU32( type a ) { return a; }
  async command int32_t MathX.castToI32( type a ) { return a; }
  async command type MathX.castFromU8( uint8_t a ) { return a; }
  async command type MathX.castFromI8( int8_t a ) { return a; }
  async command type MathX.castFromU32( uint32_t a ) { return a; }
  async command type MathX.castFromI32( int32_t a ) { return a; }
  async command type MathX.inc( type a ) { return a+1; }
  async command type MathX.dec( type a ) { return a-1; }
  async command type MathX.add( type a, type b ) { return a+b; }
  async command type MathX.sub( type a, type b ) { return a-b; }
  async command type MathX.neg( type a ) { return -a; }
  async command type MathX.not( type a ) { return ~a; }
  async command type MathX.and( type a, type b ) { return a & b; }
  async command type MathX.or( type a, type b ) { return a | b; }
  async command type MathX.xor( type a, type b ) { return a ^ b; }
  async command type MathX.sl( type a, uint8_t n ) { return a << n; }
  async command type MathX.sr( type a, uint8_t n ) { return a >> n; }
  async command bool MathX.eq( type a, type b ) { return a == b; }
  async command bool MathX.ne( type a, type b ) { return a != b; }
  async command bool MathX.lt( type a, type b ) { return a < b; }
  async command bool MathX.gt( type a, type b ) { return a > b; }
  async command bool MathX.le( type a, type b ) { return a <= b; }
  async command bool MathX.ge( type a, type b ) { return a >= b; }
EOF
  my @ops = ( 
    { type => "int8_t", MathX => "MathI8" },
    { type => "int16_t", MathX => "MathI16" },
    { type => "int32_t", MathX => "MathI32" },
    { type => "uint8_t", MathX => "MathU8" },
    { type => "uint16_t", MathX => "MathU16" },
    { type => "uint32_t", MathX => "MathU32" },
  );
  for my $op (@ops) {
    my $code = $text;
    my $repl = join "|", sort keys %{$op};
    $code =~ s{\b($repl)\b}{$op->{$1}}ge;
    print "$code\n";
  }
</perl>
}

