generic configuration CacheC(typedef  cache_key_t@integer(), uint8_t CACHE_SIZE) {
    provides interface Cache<cache_key_t>;
}
implementation {
    components MainC, new CacheP(cache_key_t, CACHE_SIZE);
    
    Cache = CacheP;
    MainC.SoftwareInit -> CacheP;
}
