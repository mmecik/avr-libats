%{#
#include "CATS/twi.cats"
%}

#define ATS_STALOADFLAG 0

#include "HATS/i2c.hats"

staload "SATS/interrupt.sats"
staload "SATS/global.sats"

//Bit and byte definitions
#define TWI_READ_BIT  0   // Bit position for R/W bit in "address byte".
#define TWI_ADR_BITS  1   // Bit position for LSB of the slave address bits in the init byte.
#define TWI_GEN_BIT   0   // Bit position for LSB of the general call bit in the init byte.

(* ****** ****** *)

//  TWI State codes

// General TWI Master staus codes
#define TWI_START                  0x08  // START has been transmitted
#define TWI_REP_START              0x10  // Repeated START has been transmitted
#define TWI_ARB_LOST               0x38  // Arbitration lost

// TWI Master Transmitter staus codes
#define TWI_MTX_ADR_ACK            0x18  // SLA+W has been tramsmitted and ACK received
#define TWI_MTX_ADR_NACK           0x20  // SLA+W has been tramsmitted and NACK received
#define TWI_MTX_DATA_ACK           0x28  // Data byte has been tramsmitted and ACK received
#define TWI_MTX_DATA_NACK          0x30  // Data byte has been tramsmitted and NACK received

// TWI Master Receiver staus codes
#define TWI_MRX_ADR_ACK            0x40  // SLA+R has been tramsmitted and ACK received
#define TWI_MRX_ADR_NACK           0x48  // SLA+R has been tramsmitted and NACK received
#define TWI_MRX_DATA_ACK           0x50  // Data byte has been received and ACK tramsmitted
#define TWI_MRX_DATA_NACK          0x58  // Data byte has been received and NACK tramsmitted

// TWI Slave Transmitter staus codes
#define TWI_STX_ADR_ACK            0xA8  // Own SLA+R has been received; ACK has been returned
#define TWI_STX_ADR_ACK_M_ARB_LOST 0xB0  // Arbitration lost in SLA+R/W as Master; own SLA+R has been received; ACK has been returned
#define TWI_STX_DATA_ACK           0xB8  // Data byte in TWDR has been transmitted; ACK has been received
#define TWI_STX_DATA_NACK          0xC0  // Data byte in TWDR has been transmitted; NOT ACK has been received
#define TWI_STX_DATA_ACK_LAST_BYTE 0xC8  // Last data byte in TWDR has been transmitted; ACK has been received

// TWI Slave Receiver status codes
#define TWI_SRX_ADR_ACK            0x60  // Own SLA+W has been received ACK has been returned
#define TWI_SRX_ADR_ACK_M_ARB_LOST 0x68  // Arbitration lost in SLA+R/W as Master; own SLA+W has been received; ACK has been returned
#define TWI_SRX_GEN_ACK            0x70  // General call address has been received; ACK has been returned
#define TWI_SRX_GEN_ACK_M_ARB_LOST 0x78  // Arbitration lost in SLA+R/W as Master; General call address has been received; ACK has been returned
#define TWI_SRX_ADR_DATA_ACK       0x80  // Previously addressed with own SLA+W; data has been received; ACK has been returned
#define TWI_SRX_ADR_DATA_NACK      0x88  // Previously addressed with own SLA+W; data has been received; NOT ACK has been returned
#define TWI_SRX_GEN_DATA_ACK       0x90  // Previously addressed with general call; data has been received; ACK has been returned
#define TWI_SRX_GEN_DATA_NACK      0x98  // Previously addressed with general call; data has been received; NOT ACK has been returned
#define TWI_SRX_STOP_RESTART       0xA0  // A STOP condition or repeated START condition has been received while still addressed as Slave

// TWI Miscellaneous status codes
#define TWI_NO_STATE               0xF8  // No relevant state information available; 
#define TWI_BUS_ERROR              0x00  // Bus error due to an illegal START or STOP condition

//macdef TWI_NO_STATE = $extval(uint8, "TWI_NO_STATE")

(* ****** ****** *)

typedef twi_address = [n:int | n > 0 | n < 128] int n

(* ****** ****** *)

absviewtype status_reg_t = $extype "status_reg_t"

viewtypedef buffer_t
  = $extype_struct "buffer_t" of {
  data= @[uchar][buff_size],
  msg_size= [n:nat | n < buff_size] int n,
  recvd_size= [p:nat | p <= buff_size] int p
}

viewtypedef twi_state_t
  = $extype_struct "twi_state_t" of {
    buffer=  buffer_t,
    status_reg= status_reg_t,
    state=uchar,
    next_byte= [m:nat | m < buff_size] int m,
    enable= () -<fun1> void,
    busy= () -<fun1> bool
}

(* ****** ****** *)

fun set_all (
  r: &status_reg_t, c: uchar
) : void = "mac#status_reg_set_all"

fun get_all (
  r: &status_reg_t
) : uchar = "mac#status_reg_get_all"

fun set_last_trans_ok (
  r: &status_reg_t, c: bool
) : void = "mac#status_reg_set_last_trans_ok"

fun get_last_trans_ok (
  r: &status_reg_t
) : bool = "mac#status_reg_get_last_trans_ok"

fun set_rx_data_in_buf (
  r: &status_reg_t, c: bool
) : void = "mac#status_reg_set_rx_data_in_buf"

fun get_rx_data_in_buf (
  r: &status_reg_t
) : bool = "mac#status_reg_get_rx_data_in_buf"

fun set_gen_address_call (
  r: &status_reg_t, c: bool
) : void = "mac#status_reg_set_gen_address_call"

fun get_gen_address_call (
  r: &status_reg_t
) : bool = "mac#status_reg_get_gen_address_call"

fun set_all_bytes_sent (
  r: &status_reg_t, b: bool
) : void = "mac#status_reg_set_all_bytes_sent"

fun get_all_bytes_sent (
  r: &status_reg_t
) : bool = "mac#status_reg_get_all_bytes_sent"

fun set_busy (
  r: &status_reg_t, b: bool
) : void = "mac#status_reg_set_busy"

fun get_busy (
  r: &status_reg_t
) : bool = "mac#status_reg_get_busy"

(* ****** ****** *)

fun get_twi_state () : [l:agz] (
  global(l), twi_state_t @ l | ptr l
) = "mac#get_twi_state"

fun slave_init (
  pf: !INT_CLEAR | addr: twi_address, gen_addr: bool
) : void

fun master_init (
  pf: !INT_CLEAR  | baud: int
) : void

fun setup_addr_byte {n:pos} {p:pos | p < 128} (
  buf: &(@[uchar][n]), addr: int p,  read: bool
) : void = "mac#avr_libats_setup_addr_byte"

fun transceiver_busy () : bool

fun get_state_info (
  pf: !INT_SET | (* *)
) : uchar

fun last_trans_ok () : bool

fun rx_data_in_buf () : [n:nat | n <= buff_size] int n

fun start_with_data {n,p:pos | n <= buff_size; p <= buff_size; p <= n} (
  pf: !INT_SET | msg: &(@[uchar][n]), sz: int p
) : void

fun get_data {n,p:pos | n <= buff_size; p <= buff_size; p <= n} (
  pf: !INT_SET | msg: &(@[uchar][n]), sz: int p
) : bool

fun start (
  pf: !INT_SET | (* *)
) : void