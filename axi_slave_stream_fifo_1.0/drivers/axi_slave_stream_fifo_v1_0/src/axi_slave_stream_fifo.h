#ifndef AXI_SLAVE_STREAM_FIFO_H
#define AXI_SLAVE_STREAM_FIFO_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xtime_l.h"

#define ASSF_CONTROL_REG_OFFSET   0
#define ASSF_STATUS_REG_OFFSET    4
#define ASSF_OCCUPANCY_REG_OFFSET 8
#define ASSF_DATA_OUT_REG_OFFSET  12

typedef enum _control_reg_mask
{
	ASSF_CLKEN   = (1 << 0),
	ASSF_RESET   = (1 << 1),
	ASSF_READ_EN = (1 << 2),
	ASSF_READ_DN = (1 << 3)
};

typedef enum _status_reg_mask
{
	ASSF_BRAM_FULL  = (1 << 0),
	ASSF_BRAM_EMPTY = (1 << 1),
	ASSF_DVALID     = (1 << 2)
};

#define EASSF_FIFO_EMPTY -2
#define EASSF_VALID_NOT_ASSERTED -3

/* max wait time in microseconds to check for data */
#define ASSF_MAX_US_WAIT 5
#define ASSF_POLL_VALID_MAX ASSF_MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_SLAVE_STREAM_FIFO register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_SLAVE_STREAM_FIFOdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void AXI_SLAVE_STREAM_FIFO_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define AXI_SLAVE_STREAM_FIFO_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_SLAVE_STREAM_FIFO register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_SLAVE_STREAM_FIFO device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 AXI_SLAVE_STREAM_FIFO_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define AXI_SLAVE_STREAM_FIFO_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the AXI_SLAVE_STREAM_FIFO instance to be worked on.
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
XStatus AXI_SLAVE_STREAM_FIFO_Reg_SelfTest(void * baseaddr_p);

extern u32  ASSF_get_ctrl_reg(const u32 baseaddr);
extern void ASSF_en_clken(const u32 baseaddr);
extern void ASSF_den_clken(const u32 baseaddr);
extern void ASSF_en_read_en(const u32 baseaddr);
extern void ASSF_den_read_en(const u32 baseaddr);
extern void ASSF_en_reset(const u32 baseaddr);
extern void ASSF_den_reset(const u32 baseaddr);

extern u8 ASSF_poll_dout_valid(const u32 baseaddr);
extern u8 ASSF_poll_bram_full(const u32 baseaddr);
extern u8 ASSF_poll_bram_empty(const u32 baseaddr);
extern u32 ASSF_poll_occupancy(const u32 baseaddr);

extern u32  ASSF_read_data(const u32 baseaddr, u32 *datout);
extern void ASSF_read_done(const u32 baseaddr);

extern void ASSF_disable_core(const u32 baseaddr);
extern void ASSF_init_core(const u32 baseaddr);

extern XTime ASSF_get_time(void);
extern XTime ASSF_elapsed_time_us(const XTime startTime);

#endif // AXI_SLAVE_STREAM_FIFO_H
