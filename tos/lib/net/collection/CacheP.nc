/* An LRU implementation of a simple cache.
 * Insert on an element not in the cache will replace the oldest.
 * Insert on an element already in the cache will refresh its age.
 */
generic module CacheP(typedef key_t @integer(), uint8_t size) {
    provides {
        interface Init;
        interface Cache<key_t>;
    }
}
implementation {
    key_t cache[size];
    uint8_t first;
    uint8_t count;

    command error_t Init.init() {
        first = 0;
        count = 0;
        return SUCCESS;
    } 

    void printCache() {
#ifdef TOSSIM
        int i;
        dbg("Cache","Cache:");
        for (i = 0; i < count; i++) {
            dbg_clear("Cache", " %08x", cache[i]);
            if (i == first)
                dbg_clear("Cache","*");
        } 
        dbg_clear("Cache","\n");
#endif
    }

    /* if key is in cache returns the index (offset by first), otherwise returns count */
    uint8_t lookup(key_t key) {
        uint8_t i;
	key_t k;
        for (i = 0; i < count; i++) {
	   k = cache[(i + first) % size];
           if (k == key)
            break; 
        }
        return i;
    }

    /* remove the entry with index i (relative to first) */
    void remove(uint8_t i) {
        uint8_t j;
        if (i >= count) 
            return;
        if (i == 0) {
            //shift all by moving first
            first = (first + 1) % size;
        } else {
            //shift everyone down
            for (j = i; j < count; j++) {
                cache[(j + first) % size] = cache[(j + first + 1) % size];
            }
        }
        count--;
    }

    command void Cache.insert(key_t key) {
        uint8_t i;
        if (count == size ) {
            //remove someone. If item not in 
            //cache, remove the first item.
            //otherwise remove the item temporarily for
            //reinsertion. This moves the item up in the
            //LRU stack.
            i = lookup(key);
            remove(i % count);
        }
        //now count < size
        cache[(first + count) % size] = key;
        count++;
    }

    command bool Cache.lookup(key_t key) {
        return (lookup(key) < count);
    }

    /* Removes the item if in the cache.
     * Returns SUCCESS if item was in cache,
     *         FAIL if item was not in cache */
    command error_t Cache.remove(key_t key) {
    }

}
