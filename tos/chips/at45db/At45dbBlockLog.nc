interface At45dbBlockLog {
  command void setFlip(bool flip);
  command bool flipped();

  event bool writeHook();
  command void writeContinue(error_t error);

  command at45page_t npages();
  command at45page_t remap(at45page_t page);
}
