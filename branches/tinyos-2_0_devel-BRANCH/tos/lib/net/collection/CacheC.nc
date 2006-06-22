generic configuration CacheC(typedef key_t @integer(), uint8_t CACHE_SIZE) {
    provides interface Cache<key_t>;
}
implementation {
    components MainC, new CacheP(key_t, CACHE_SIZE);
    
    Cache = CacheP;
    MainC.SoftwareInit -> CacheP;
}
