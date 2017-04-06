
#ifndef FIFO_AXI_BUFFER_H
#define FIFO_AXI_BUFFER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET 0
#define FIFO_AXI_BUFFER_S00_AXI_STATUS_REG_OFFSET 4
#define FIFO_AXI_BUFFER_S00_AXI_DCOUNT_REG_OFFSET 8
#define FIFO_AXI_BUFFER_S00_AXI_DOUT_REG_OFFSET 12
#define FIFO_AXI_BUFFER_S00_AXI_DIN_REG_OFFSET 16

/* control register bit positions */
#define RESET (1 << 0)
#define RD_EN (1 << 1)
#define WR_EN (1 << 2)

/* status register bit positions */
#define RD_VALID (1 << 0)
#define WR_FULL  (1 << 1)
#define RD_EMPTY (1 << 2)

/* DATA WIDTHS */
#define RW_DAT_WIDTH 16
#define DCOUNT_WIDTH 10


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a FIFO_AXI_BUFFER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the FIFO_AXI_BUFFERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void FIFO_AXI_BUFFER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define FIFO_AXI_BUFFER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a FIFO_AXI_BUFFER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the FIFO_AXI_BUFFER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 FIFO_AXI_BUFFER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define FIFO_AXI_BUFFER_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the FIFO_AXI_BUFFER instance to be worked on.
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
XStatus FIFO_AXI_BUFFER_Reg_SelfTest(void * baseaddr_p);


/* fifo functions */
extern void fifo_write_data(u32 FIFO_AXI_BUFFER_BASE_ADDR,u32 din);
extern u32  fifo_get_data(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern void fifo_disable_write(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern void fifo_set_write(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern void fifo_disable_read(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern void fifo_set_read(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern void fifo_reset(u32 FIFO_AXI_BUFFER_BASE_ADDR);
extern u32  fifo_get_status_register(u32 FIFO_AXI_BUFFER_BASE_ADDR);

#endif // FIFO_AXI_BUFFER_H
