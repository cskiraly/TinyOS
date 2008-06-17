/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'TestSerialMsg'
 * message type.
 */

public class TestSerialMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 100;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 9;

    /** Create a new TestSerialMsg of size 100. */
    public TestSerialMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new TestSerialMsg of the given data_length. */
    public TestSerialMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg with the given data_length
     * and base offset.
     */
    public TestSerialMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg using the given byte array
     * as backing store.
     */
    public TestSerialMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public TestSerialMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public TestSerialMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg embedded in the given message
     * at the given base offset.
     */
    public TestSerialMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new TestSerialMsg embedded in the given message
     * at the given base offset and length.
     */
    public TestSerialMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <TestSerialMsg> \n";
      try {
        s += "  [counter=0x"+Long.toHexString(get_counter())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [x=";
        for (int i = 0; i < 98; i++) {
          s += "0x"+Long.toHexString(getElement_x(i) & 0xff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: counter
    //   Field type: int, unsigned
    //   Offset (bits): 0
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'counter' is signed (false).
     */
    public static boolean isSigned_counter() {
        return false;
    }

    /**
     * Return whether the field 'counter' is an array (false).
     */
    public static boolean isArray_counter() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'counter'
     */
    public static int offset_counter() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'counter'
     */
    public static int offsetBits_counter() {
        return 0;
    }

    /**
     * Return the value (as a int) of the field 'counter'
     */
    public int get_counter() {
        return (int)getUIntBEElement(offsetBits_counter(), 16);
    }

    /**
     * Set the value of the field 'counter'
     */
    public void set_counter(int value) {
        setUIntBEElement(offsetBits_counter(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'counter'
     */
    public static int size_counter() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'counter'
     */
    public static int sizeBits_counter() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: x
    //   Field type: short[], unsigned
    //   Offset (bits): 16
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'x' is signed (false).
     */
    public static boolean isSigned_x() {
        return false;
    }

    /**
     * Return whether the field 'x' is an array (true).
     */
    public static boolean isArray_x() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'x'
     */
    public static int offset_x(int index1) {
        int offset = 16;
        if (index1 < 0 || index1 >= 98) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'x'
     */
    public static int offsetBits_x(int index1) {
        int offset = 16;
        if (index1 < 0 || index1 >= 98) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return offset;
    }

    /**
     * Return the entire array 'x' as a short[]
     */
    public short[] get_x() {
        short[] tmp = new short[98];
        for (int index0 = 0; index0 < numElements_x(0); index0++) {
            tmp[index0] = getElement_x(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'x' from the given short[]
     */
    public void set_x(short[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_x(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a short) of the array 'x'
     */
    public short getElement_x(int index1) {
        return (short)getUIntBEElement(offsetBits_x(index1), 8);
    }

    /**
     * Set an element of the array 'x'
     */
    public void setElement_x(int index1, short value) {
        setUIntBEElement(offsetBits_x(index1), 8, value);
    }

    /**
     * Return the total size, in bytes, of the array 'x'
     */
    public static int totalSize_x() {
        return (784 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'x'
     */
    public static int totalSizeBits_x() {
        return 784;
    }

    /**
     * Return the size, in bytes, of each element of the array 'x'
     */
    public static int elementSize_x() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'x'
     */
    public static int elementSizeBits_x() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'x'
     */
    public static int numDimensions_x() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'x'
     */
    public static int numElements_x() {
        return 98;
    }

    /**
     * Return the number of elements in the array 'x'
     * for the given dimension.
     */
    public static int numElements_x(int dimension) {
      int array_dims[] = { 98,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'x' with a String
     */
    public void setString_x(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_x(i, (short)s.charAt(i));
         }
         setElement_x(i, (short)0); //null terminate
    }

    /**
     * Read the array 'x' as a String
     */
    public String getString_x() { 
         char carr[] = new char[Math.min(net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH,98)];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_x(i) == (char)0) break;
             carr[i] = (char)getElement_x(i);
         }
         return new String(carr,0,i);
    }

}