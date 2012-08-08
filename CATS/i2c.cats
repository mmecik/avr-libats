#ifndef _AVR_LIBATS_I2C_HEADER
#define _AVR_LIBATS_I2C_HEADER

#define BUFF_SIZE 4

//Bit and byte definitions
#define TWI_READ_BIT  0   // Bit position for R/W bit in "address byte".
#define TWI_ADR_BITS  1   // Bit position for LSB of the slave address bits in the init byte.
#define TWI_GEN_BIT   0   // Bit position for LSB of the general call bit in the init byte.

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

#define status_reg_set_all(reg, char) reg.all = char
#define status_reg_get_all(reg) reg.all

#define status_reg_set_last_trans_ok(reg, char)  reg.last_trans_ok = char
#define status_reg_get_last_trans_ok(reg) reg.last_trans_ok

#define status_reg_set_rx_data_in_buf(reg, char)  reg.rx_data_in_buf = char
#define status_reg_get_rx_data_in_buf(reg) reg.rx_data_in_buf

#define status_reg_set_gen_address_call(reg, char)  reg.rx_data_in_buf = char
#define status_reg_get_gen_address_call(reg) reg.rx_data_in_buf

#define status_reg_set_all_bytes_sent(reg, bool)  reg.all_bytes_sent = bool
#define status_reg_get_all_bytes_sent(reg) reg.all_bytes_sent

#define set_address(address, general_enabled) TWAR = (address << TWI_ADR_BITS) | (general_enabled << TWI_GEN_BIT)

union status_reg_t
{
  unsigned char all;
  struct
  {
    unsigned char last_trans_ok:1;
    unsigned char rx_data_in_buf:1;
    unsigned char gen_address_call:1;
    unsigned char all_bytes_sent:1;
    unsigned char unused_bits:4;
  };
};

// ATS doesn't have a union type
typedef union status_reg_t status_reg_t;

typedef struct {
  unsigned char data[BUFF_SIZE];
  uint8_t msg_size;
  uint8_t recvd_size;
} buffer_t;

typedef struct {
  buffer_t buffer;
  status_reg_t status_reg;
  unsigned char state;
  uint8_t next_byte;
} twi_state_t;

#define get_twi_state() (twi_state_t * volatile)&twi_state
#endif
