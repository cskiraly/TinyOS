includes HPLAT45DB;
interface HPLAT45DB {
  command result_t waitIdle();
  event result_t waitIdleDone();

  command result_t waitCompare();
  event result_t waitCompareDone(bool compareOk);

  command result_t fill(uint8_t cmd, at45page_t page);
  event result_t fillDone();

  command result_t flush(uint8_t cmd, at45page_t page);
  event result_t flushDone();

  command result_t compare(uint8_t cmd, at45page_t page);
  event result_t compareDone();

  command result_t erase(uint8_t cmd, at45page_t page);
  event result_t eraseDone();

  command result_t read(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
			uint8_t *data, at45pageoffset_t count);
  event result_t readDone();

  command result_t crc(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
		       at45pageoffset_t count, uint16_t baseCrc);
  event result_t crcDone(uint16_t computedCrc);

  command result_t write(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
			 uint8_t *data, at45pageoffset_t count);
  event result_t writeDone();
}
