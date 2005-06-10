package net.tinyos.message.telos;

public class TOSMsg extends net.tinyos.message.TOSMsg
{
    public message_t radioHeader;
    public ActiveMsg amHeader;

    protected void init(byte[] data, int base_offset, int data_length) {
	super.init(data, base_offset, data_length);
	// Alias structures representing the radio and AM structures onto our data
	radioHeader = new message_t(dataGet());
	amHeader = new ActiveMsg(dataGet(), radioHeader.offset_data(0));
    }

    public int get_addr() {
	return radioHeader.get_header_addr();
    }

    public void set_addr(int value) {
	radioHeader.set_header_addr(value);
    }

    public short get_type() {
	return amHeader.get_type();
    }

    public void set_type(short value) {
	amHeader.set_type(value);
    }

    public short get_length() {
	return radioHeader.get_header_length();
    }

    public void set_length(short value) {
	radioHeader.set_header_length(value);
    }

    public int offset_data(int index1) {
	return amHeader.offset_data(index1) + amHeader.baseOffset();
    }
}
