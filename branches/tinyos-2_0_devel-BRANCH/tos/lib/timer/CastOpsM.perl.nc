<perl>
  my @ops = ( 
    { type => "int8_t", tag => "I8" },
    { type => "int16_t", tag => "I16" },
    { type => "int32_t", tag => "I32" },
    { type => "uint8_t", tag => "U8" },
    { type => "uint16_t", tag => "U16" },
    { type => "uint32_t", tag => "U32" },
  );

  sub CastOp_tag {
    my %arg = @_;
    for my $op1 (@ops) {
      for my $op2 (@ops) {
	my $t = $arg{text};
	$t =~ s/\{type1\}/$op1->{type}/g;
	$t =~ s/\{type2\}/$op2->{type}/g;
	$t =~ s/\{tag1\}/$op1->{tag}/g;
	$t =~ s/\{tag2\}/$op2->{tag}/g;
	$t =~ s/\n$//;
	print $t;
      }
    }
    1;
  }
  $file->{tags}->add_tag("castop",\&CastOp_tag);
</perl>

module CastOpsM
{
<castop>
  provides interface CastOps<{type1},{type2}> as Cast{tag1}{tag2}; 
</castop>
}
implementation
{
<castop>
  async command {type1} Cast{tag1}{tag2}.left( {type2} a ) { return a; }
  async command {type2} Cast{tag1}{tag2}.right( {type1} a ) { return a; }
</castop>
}

