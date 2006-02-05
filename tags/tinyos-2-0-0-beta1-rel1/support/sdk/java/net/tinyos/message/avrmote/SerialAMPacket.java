/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'SerialAMPacket'
 * message type.
 */

package net.tinyos.message.avrmote;

public class SerialAMPacket extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 5;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = -1;

    /** Create a new SerialAMPacket of size 5. */
    public SerialAMPacket() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new SerialAMPacket of the given data_length. */
    public SerialAMPacket(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket with the given data_length
     * and base offset.
     */
    public SerialAMPacket(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket using the given byte array
     * as backing store.
     */
    public SerialAMPacket(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket using the given byte array
     * as backing store, with the given base offset.
     */
    public SerialAMPacket(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public SerialAMPacket(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket embedded in the given message
     * at the given base offset.
     */
    public SerialAMPacket(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialAMPacket embedded in the given message
     * at the given base offset and length.
     */
    public SerialAMPacket(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <SerialAMPacket> \n";
      try {
        s += "  [header.addr=0x"+Long.toHexString(get_header_addr())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.length=0x"+Long.toHexString(get_header_length())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.group=0x"+Long.toHexString(get_header_group())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.type=0x"+Long.toHexString(get_header_type())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.addr
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.addr' is signed (false).
     */
    public static boolean isSigned_header_addr() {
        return false;
    }

    /**
     * Return whether the field 'header.addr' is an array (false).
     */
    public static boolean isArray_header_addr() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.addr'
     */
    public static int offset_header_addr() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.addr'
     */
    public static int offsetBits_header_addr() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'header.addr'
     */
    public short get_header_addr() {
        return (short)getSIntBEElement(offsetBits_header_addr(), 16);
    }

    /**
     * Set the value of the field 'header.addr'
     */
    public void set_header_addr(short value) {
        setSIntBEElement(offsetBits_header_addr(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.addr'
     */
    public static int size_header_addr() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.addr'
     */
    public static int sizeBits_header_addr() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.length
    //   Field type: short, unsigned
    //   Offset (bits): 16
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.length' is signed (false).
     */
    public static boolean isSigned_header_length() {
        return false;
    }

    /**
     * Return whether the field 'header.length' is an array (false).
     */
    public static boolean isArray_header_length() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.length'
     */
    public static int offset_header_length() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.length'
     */
    public static int offsetBits_header_length() {
        return 16;
    }

    /**
     * Return the value (as a short) of the field 'header.length'
     */
    public short get_header_length() {
        return (short)getUIntBEElement(offsetBits_header_length(), 8);
    }

    /**
     * Set the value of the field 'header.length'
     */
    public void set_header_length(short value) {
        setUIntBEElement(offsetBits_header_length(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.length'
     */
    public static int size_header_length() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.length'
     */
    public static int sizeBits_header_length() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.group
    //   Field type: byte, unsigned
    //   Offset (bits): 24
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.group' is signed (false).
     */
    public static boolean isSigned_header_group() {
        return false;
    }

    /**
     * Return whether the field 'header.group' is an array (false).
     */
    public static boolean isArray_header_group() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.group'
     */
    public static int offset_header_group() {
        return (24 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.group'
     */
    public static int offsetBits_header_group() {
        return 24;
    }

    /**
     * Return the value (as a byte) of the field 'header.group'
     */
    public byte get_header_group() {
        return (byte)getSIntBEElement(offsetBits_header_group(), 8);
    }

    /**
     * Set the value of the field 'header.group'
     */
    public void set_header_group(byte value) {
        setSIntBEElement(offsetBits_header_group(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.group'
     */
    public static int size_header_group() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.group'
     */
    public static int sizeBits_header_group() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.type
    //   Field type: byte, unsigned
    //   Offset (bits): 32
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.type' is signed (false).
     */
    public static boolean isSigned_header_type() {
        return false;
    }

    /**
     * Return whether the field 'header.type' is an array (false).
     */
    public static boolean isArray_header_type() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.type'
     */
    public static int offset_header_type() {
        return (32 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.type'
     */
    public static int offsetBits_header_type() {
        return 32;
    }

    /**
     * Return the value (as a byte) of the field 'header.type'
     */
    public byte get_header_type() {
        return (byte)getSIntBEElement(offsetBits_header_type(), 8);
    }

    /**
     * Set the value of the field 'header.type'
     */
    public void set_header_type(byte value) {
        setSIntBEElement(offsetBits_header_type(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.type'
     */
    public static int size_header_type() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.type'
     */
    public static int sizeBits_header_type() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data
    //   Field type: short[], unsigned
    //   Offset (bits): 40
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data' is signed (false).
     */
    public static boolean isSigned_data() {
        return false;
    }

    /**
     * Return whether the field 'data' is an array (true).
     */
    public static boolean isArray_data() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'data'
     */
    public static int offset_data(int index1) {
        int offset = 40;
        if (index1 < 0) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data'
     */
    public static int offsetBits_data(int index1) {
        int offset = 40;
        if (index1 < 0) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return offset;
    }

    /**
     * Return the entire array 'data' as a short[]
     */
    public short[] get_data() {
        throw new IllegalArgumentException("Cannot get field as array - unknown size");
    }

    /**
     * Set the contents of the array 'data' from the given short[]
     */
    public void set_data(short[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_data(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a short) of the array 'data'
     */
    public short getElement_data(int index1) {
        return (short)getUIntBEElement(offsetBits_data(index1), 8);
    }

    /**
     * Set an element of the array 'data'
     */
    public void setElement_data(int index1, short value) {
        setUIntBEElement(offsetBits_data(index1), 8, value);
    }

    /**
     * Return the size, in bytes, of each element of the array 'data'
     */
    public static int elementSize_data() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'data'
     */
    public static int elementSizeBits_data() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'data'
     */
    public static int numDimensions_data() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'data'
     * for the given dimension.
     */
    public static int numElements_data(int dimension) {
      int array_dims[] = { 0,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'data' with a String
     */
    public void setString_data(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_data(i, (short)s.charAt(i));
         }
         setElement_data(i, (short)0); //null terminate
    }

    /**
     * Read the array 'data' as a String
     */
    public String getString_data() { 
         char carr[] = new char[net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_data(i) == (char)0) break;
             carr[i] = (char)getElement_data(i);
         }
         return new String(carr,0,i);
    }

}
