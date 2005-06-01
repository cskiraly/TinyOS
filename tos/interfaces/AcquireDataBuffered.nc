// $Id: AcquireDataBuffered.nc,v 1.1.2.2 2005-06-01 03:12:28 janhauer Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Data acquisition interface. See TEP 101.
 * 
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

interface AcquireDataBuffered {
    /** Prepare to acquire 'count' samples into 'buffer', with
     *  'rate' microseconds between each sample.
     *  There must be a call to 'prepare' before every call to 'getData'
     *  @param buffer Buffer in which to store samples
     *  @param count Number of samples to acquire
     *  @param rate Interval in microseconds between each sample. The
     *    actual rate may be (very) different from this value, use
     *    the getRate command to find out what value will be used.
     *  @return SUCCESS if request accepted, EBUSY if it is refused,
     *    EINVAL if the parameters are invalid.
     *    'dataReady' or 'error' will be signaled if SUCCESS is returned
     */
    command error_t prepare(uint16_t *buffer, uint16_t count, 
                             uint32_t rate);

    /** Return the sampling rate for the next acquisition
     *  @return Sampling interval in microseconds that will be used by the
     *    next call to getData.
     */
    command uint32_t getRate();

    /** Request data. A call to 'getData' must be preceded by a call to
     *  'prepare' to set up the data acquisition parameters.
     *  @return SUCCESS if request accepted, EBUSY if it is refused
     *    'dataReady' or 'error' will be signaled if SUCCESS is returned.
     *    The data acquisition SHOULD start immediately (within 
     *    hardware constraints).
     */
    async command error_t getData();

    /** Data has been acquired.
     * @param buffer Buffer containing the data.
     *   Samples are "left-justified" within each 16-bit integer, i.e., if
     *   the data is acquired with n bits of precision, each value is 
     *   shifted left by 16-n bits.
     * @param count Number of samples acquired.
     */
    event void dataReady(uint16_t *buffer, uint16_t count);

    /** Signal that the data acquisition failed
     *  @param info error information
     */
    event void error(uint16_t info);
}

