typedef enum {
  SUCCESS        = 0,
  ESIZE          = 1,           // Parameter passed in was too big.
  ECANCEL        = 2,           // Operation cancelled by a call.
} error_t;
