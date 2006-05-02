/* Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 */
#ifndef MESSAGE_H
#define MESSAGE_H

#include <stdint.h>
#include <stdlib.h>

typedef struct tmsg tmsg_t;

void tmsg_fail(void);

tmsg_t *new_tmsg(void *packet, size_t len);
void free_tmsg(tmsg_t *msg);
void *tmsg_data(tmsg_t *msg);
size_t tmsg_length(tmsg_t *msg);

uint64_t tmsg_read_ule(tmsg_t *msg, size_t bit_offset, size_t bit_length);
int64_t tmsg_read_le(tmsg_t *msg, size_t bit_offset, size_t bit_length);
void tmsg_write_ule(tmsg_t *msg, size_t bit_offset, size_t bit_length, uint64_t value);
void tmsg_write_le(tmsg_t *msg, size_t bit_offset, size_t bit_length, int64_t value);

uint64_t tmsg_read_ube(tmsg_t *msg, size_t bit_offset, size_t bit_length);
int64_t tmsg_read_be(tmsg_t *msg, size_t bit_offset, size_t bit_length);
void tmsg_write_ube(tmsg_t *msg, size_t bit_offset, size_t bit_length, uint64_t value);
void tmsg_write_be(tmsg_t *msg, size_t bit_offset, size_t bit_length, int64_t value);

float tmsg_read_float_le(tmsg_t *msg, size_t offset);
void tmsg_write_float_le(tmsg_t *msg, size_t offset, float x);
float tmsg_read_float_be(tmsg_t *msg, size_t offset);
void tmsg_write_float_be(tmsg_t *msg, size_t offset, float x);

#endif
