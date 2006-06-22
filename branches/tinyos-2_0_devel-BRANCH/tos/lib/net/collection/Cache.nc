/* Very simple cache of a single type */
interface Cache<t> {
    /* Inserts an item in the cache, evicting a previous one if 
     * necessary.
     * An atomic lookup after insert should return true.
     */
    command void insert(t item);

    /* Returns true if item is in the cache, false otherwise */
    command bool lookup(t item);
    command errot_t remove(t item);
}

