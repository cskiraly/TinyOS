

module CastOpsM
{

  provides interface CastOps<int8_t,int8_t> as CastI8I8; 
  provides interface CastOps<int8_t,int16_t> as CastI8I16; 
  provides interface CastOps<int8_t,int32_t> as CastI8I32; 
  provides interface CastOps<int8_t,uint8_t> as CastI8U8; 
  provides interface CastOps<int8_t,uint16_t> as CastI8U16; 
  provides interface CastOps<int8_t,uint32_t> as CastI8U32; 
  provides interface CastOps<int16_t,int8_t> as CastI16I8; 
  provides interface CastOps<int16_t,int16_t> as CastI16I16; 
  provides interface CastOps<int16_t,int32_t> as CastI16I32; 
  provides interface CastOps<int16_t,uint8_t> as CastI16U8; 
  provides interface CastOps<int16_t,uint16_t> as CastI16U16; 
  provides interface CastOps<int16_t,uint32_t> as CastI16U32; 
  provides interface CastOps<int32_t,int8_t> as CastI32I8; 
  provides interface CastOps<int32_t,int16_t> as CastI32I16; 
  provides interface CastOps<int32_t,int32_t> as CastI32I32; 
  provides interface CastOps<int32_t,uint8_t> as CastI32U8; 
  provides interface CastOps<int32_t,uint16_t> as CastI32U16; 
  provides interface CastOps<int32_t,uint32_t> as CastI32U32; 
  provides interface CastOps<uint8_t,int8_t> as CastU8I8; 
  provides interface CastOps<uint8_t,int16_t> as CastU8I16; 
  provides interface CastOps<uint8_t,int32_t> as CastU8I32; 
  provides interface CastOps<uint8_t,uint8_t> as CastU8U8; 
  provides interface CastOps<uint8_t,uint16_t> as CastU8U16; 
  provides interface CastOps<uint8_t,uint32_t> as CastU8U32; 
  provides interface CastOps<uint16_t,int8_t> as CastU16I8; 
  provides interface CastOps<uint16_t,int16_t> as CastU16I16; 
  provides interface CastOps<uint16_t,int32_t> as CastU16I32; 
  provides interface CastOps<uint16_t,uint8_t> as CastU16U8; 
  provides interface CastOps<uint16_t,uint16_t> as CastU16U16; 
  provides interface CastOps<uint16_t,uint32_t> as CastU16U32; 
  provides interface CastOps<uint32_t,int8_t> as CastU32I8; 
  provides interface CastOps<uint32_t,int16_t> as CastU32I16; 
  provides interface CastOps<uint32_t,int32_t> as CastU32I32; 
  provides interface CastOps<uint32_t,uint8_t> as CastU32U8; 
  provides interface CastOps<uint32_t,uint16_t> as CastU32U16; 
  provides interface CastOps<uint32_t,uint32_t> as CastU32U32; 
}
implementation
{

  async command int8_t CastI8I8.left( int8_t a ) { return a; }
  async command int8_t CastI8I8.right( int8_t a ) { return a; }
  async command int8_t CastI8I16.left( int16_t a ) { return a; }
  async command int16_t CastI8I16.right( int8_t a ) { return a; }
  async command int8_t CastI8I32.left( int32_t a ) { return a; }
  async command int32_t CastI8I32.right( int8_t a ) { return a; }
  async command int8_t CastI8U8.left( uint8_t a ) { return a; }
  async command uint8_t CastI8U8.right( int8_t a ) { return a; }
  async command int8_t CastI8U16.left( uint16_t a ) { return a; }
  async command uint16_t CastI8U16.right( int8_t a ) { return a; }
  async command int8_t CastI8U32.left( uint32_t a ) { return a; }
  async command uint32_t CastI8U32.right( int8_t a ) { return a; }
  async command int16_t CastI16I8.left( int8_t a ) { return a; }
  async command int8_t CastI16I8.right( int16_t a ) { return a; }
  async command int16_t CastI16I16.left( int16_t a ) { return a; }
  async command int16_t CastI16I16.right( int16_t a ) { return a; }
  async command int16_t CastI16I32.left( int32_t a ) { return a; }
  async command int32_t CastI16I32.right( int16_t a ) { return a; }
  async command int16_t CastI16U8.left( uint8_t a ) { return a; }
  async command uint8_t CastI16U8.right( int16_t a ) { return a; }
  async command int16_t CastI16U16.left( uint16_t a ) { return a; }
  async command uint16_t CastI16U16.right( int16_t a ) { return a; }
  async command int16_t CastI16U32.left( uint32_t a ) { return a; }
  async command uint32_t CastI16U32.right( int16_t a ) { return a; }
  async command int32_t CastI32I8.left( int8_t a ) { return a; }
  async command int8_t CastI32I8.right( int32_t a ) { return a; }
  async command int32_t CastI32I16.left( int16_t a ) { return a; }
  async command int16_t CastI32I16.right( int32_t a ) { return a; }
  async command int32_t CastI32I32.left( int32_t a ) { return a; }
  async command int32_t CastI32I32.right( int32_t a ) { return a; }
  async command int32_t CastI32U8.left( uint8_t a ) { return a; }
  async command uint8_t CastI32U8.right( int32_t a ) { return a; }
  async command int32_t CastI32U16.left( uint16_t a ) { return a; }
  async command uint16_t CastI32U16.right( int32_t a ) { return a; }
  async command int32_t CastI32U32.left( uint32_t a ) { return a; }
  async command uint32_t CastI32U32.right( int32_t a ) { return a; }
  async command uint8_t CastU8I8.left( int8_t a ) { return a; }
  async command int8_t CastU8I8.right( uint8_t a ) { return a; }
  async command uint8_t CastU8I16.left( int16_t a ) { return a; }
  async command int16_t CastU8I16.right( uint8_t a ) { return a; }
  async command uint8_t CastU8I32.left( int32_t a ) { return a; }
  async command int32_t CastU8I32.right( uint8_t a ) { return a; }
  async command uint8_t CastU8U8.left( uint8_t a ) { return a; }
  async command uint8_t CastU8U8.right( uint8_t a ) { return a; }
  async command uint8_t CastU8U16.left( uint16_t a ) { return a; }
  async command uint16_t CastU8U16.right( uint8_t a ) { return a; }
  async command uint8_t CastU8U32.left( uint32_t a ) { return a; }
  async command uint32_t CastU8U32.right( uint8_t a ) { return a; }
  async command uint16_t CastU16I8.left( int8_t a ) { return a; }
  async command int8_t CastU16I8.right( uint16_t a ) { return a; }
  async command uint16_t CastU16I16.left( int16_t a ) { return a; }
  async command int16_t CastU16I16.right( uint16_t a ) { return a; }
  async command uint16_t CastU16I32.left( int32_t a ) { return a; }
  async command int32_t CastU16I32.right( uint16_t a ) { return a; }
  async command uint16_t CastU16U8.left( uint8_t a ) { return a; }
  async command uint8_t CastU16U8.right( uint16_t a ) { return a; }
  async command uint16_t CastU16U16.left( uint16_t a ) { return a; }
  async command uint16_t CastU16U16.right( uint16_t a ) { return a; }
  async command uint16_t CastU16U32.left( uint32_t a ) { return a; }
  async command uint32_t CastU16U32.right( uint16_t a ) { return a; }
  async command uint32_t CastU32I8.left( int8_t a ) { return a; }
  async command int8_t CastU32I8.right( uint32_t a ) { return a; }
  async command uint32_t CastU32I16.left( int16_t a ) { return a; }
  async command int16_t CastU32I16.right( uint32_t a ) { return a; }
  async command uint32_t CastU32I32.left( int32_t a ) { return a; }
  async command int32_t CastU32I32.right( uint32_t a ) { return a; }
  async command uint32_t CastU32U8.left( uint8_t a ) { return a; }
  async command uint8_t CastU32U8.right( uint32_t a ) { return a; }
  async command uint32_t CastU32U16.left( uint16_t a ) { return a; }
  async command uint16_t CastU32U16.right( uint32_t a ) { return a; }
  async command uint32_t CastU32U32.left( uint32_t a ) { return a; }
  async command uint32_t CastU32U32.right( uint32_t a ) { return a; }
}

