interface Resource {
  /**
   * Request access to a shared resource. You must call release()
   * when you are done with it.
   * @return SUCCESS You have the resource.
   *         EBUSY The resource is busy. The granted() event will
   *               be signaled when you have the resource.
   */
  command error_t request();

  /**
   * You have received access to this resource.
   */
  event void granted();

  /**
   * Release a shared resource you previously acquired.
   */
  command void release();

  /**
   * Some other component has requested this resource. You might
   * want to consider releasing it.
   */
  event void requested();
}
