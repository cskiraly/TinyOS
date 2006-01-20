package net.tinyos.message.telos;

public class TOSMsg extends net.tinyos.message.TOSMsg
{
    public SerialAMPacket packet;

    protected void init(byte[] data, int base_offset, int data_length) {
	super.init(data, base_offset, data_length);
	// Alias structures representing the radio and AM structures onto our data
	packet = new SerialAMPacket(dataGet());
    }

    public int get_addr() {
	return packet.get_header_addr();
    }

    public void set_addr(int value) {
	packet.set_header_addr((short) (value & 0xffff));
    }

    public short get_type() {
	return packet.get_header_type();
    }

    public void set_type(short value) {
	packet.set_header_type((byte) (value & 0xff));
    }

    public short get_length() {
	return packet.get_header_length();
    }

    public void set_length(short value) {
	packet.set_header_length((byte) (value & 0xff));
    }

    public int offset_data(int index1) {
	return packet.offset_data(index1);
    }
}
