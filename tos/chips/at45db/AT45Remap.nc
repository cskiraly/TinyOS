includes HALAT45DB;
interface AT45Remap {
  /* Returns AT45_MAX_PAGES for invalid request (out of volume) */
  command at45page_t remap(volume_t volume, at45page_t volumePage);
}
