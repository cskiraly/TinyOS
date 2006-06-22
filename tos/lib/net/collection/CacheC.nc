generic configuration CacheC(typedef key_t, uint8_t CACHE_SIZE) {
    provides interface Cache<key_t>;
}
implementation {
    components MainC, new CacheP(key_t, CACHE_SIZE);

    MainC.SoftwareInit -> CacheP;
}
