
#ifndef AXI_BRAM_FIFO_CONTROLLER_H
#define AXI_BRAM_FIFO_CONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xtime_l.h"

#define AFIFO_CTRL_REG 0
#define AFIFO_DIN_REG 4
#define AFIFO_DOUT_REG 8
#define AFIFO_STATUS_REG 12

#define BRAM_ADDR_WIDTH 10

#define EAFIFO_FIFO_FULL -1
#define EAFIFO_FIFO_EMPTY -2
#define EAFIFO_VALID_NOT_ASSERTED -3

/* max wait time in microseconds to check for data */
#define AFIFO_MAX_US_WAIT 5
#define AFIFO_POLL_VALID_MAX AFIFO_MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)

typedef enum _control_reg_bits{
	AFIFO_READ_EN  = (1 << 0),
	AFIFO_WRITE_EN = (1 << 1),
	AFIFO_CLKEN   = (1 << 2),
	AFIFO_RESET    = (1 << 3)
};

typedef enum _status_reg_bits{
	AFIFO_OCCUPANCY  = 0x3ff, // 10 bits
	AFIFO_DVALID     = (1 << BRAM_ADDR_WIDTH),
	AFIFO_BRAM_FULL  = (1 << BRAM_ADDR_WIDTH + 1),
	AFIFO_BRAM_EMPTY = (1 << BRAM_ADDR_WIDTH + 2)
};


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_BRAM_FIFO_CONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_CONTROLLERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void AXI_BRAM_FIFO_CONTROLLER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define AXI_BRAM_FIFO_CONTROLLER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_BRAM_FIFO_CONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 AXI_BRAM_FIFO_CONTROLLER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define AXI_BRAM_FIFO_CONTROLLER_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

/************************** Function Prototypes ****************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the AXI_BRAM_FIFO_CONTROLLER instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus AXI_BRAM_FIFO_CONTROLLER_Reg_SelfTest(void * baseaddr_p);

extern u32  AFIFO_get_ctrl_reg(const u32 baseaddr);
extern void AFIFO_en_write_en(const u32 baseaddr);
extern void AFIFO_den_write_en(const u32 baseaddr);
extern void AFIFO_en_clken(const u32 baseaddr);
extern void AFIFO_den_clken(const u32 baseaddr);
extern void AFIFO_en_read_en(const u32 baseaddr);
extern void AFIFO_den_read_en(const u32 baseaddr);
extern void AFIFO_en_reset(const u32 baseaddr);
extern void AFIFO_den_reset(const u32 baseaddr);

extern u8 AFIFO_poll_dout_valid(const u32 baseaddr);
extern u8 AFIFO_poll_bram_full(const u32 baseaddr);
extern u8 AFIFO_poll_bram_empty(const u32 baseaddr);
extern u32 AFIFO_poll_occupancy(const u32 baseaddr);

extern u32  AFIFO_write_data(const u32 baseaddr, const u32 datin);
extern void AFIFO_read_prep(const u32 baseaddr);
extern u32  AFIFO_read_data(const u32 baseaddr, u32 *datout);

extern void AFIFO_print_error(const int err);
extern void AFIFO_disable_core(const u32 baseaddr);
extern void AFIFO_init_core(const u32 baseaddr);

extern XTime AFIFO_get_time(void);
extern XTime AFIFO_elapsed_time_us(const XTime startTime);


#endif // AXI_BRAM_FIFO_CONTROLLER_H
