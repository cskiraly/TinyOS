/** Defines data type for storing interrupt mask state during atomic. */
typedef uint8_t __nesc_atomic_t;

/** Saves current interrupt mask state and disables interrupts. */
inline __nesc_atomic_t __nesc_atomic_start(void) __attribute__((spontaneous)) {
    return 0;
}

/** Restores interrupt mask to original state. */
inline void __nesc_atomic_end(__nesc_atomic_t original_SREG) __attribute__((spontaneous)) {}

inline void __nesc_atomic_sleep()
{}

inline void __nesc_enable_interrupt() {}
