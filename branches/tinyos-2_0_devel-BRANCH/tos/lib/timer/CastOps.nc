
interface CastOps<type1,type2>
{
  async command type1 left( type2 a );
  async command type2 right( type1 a );
}

