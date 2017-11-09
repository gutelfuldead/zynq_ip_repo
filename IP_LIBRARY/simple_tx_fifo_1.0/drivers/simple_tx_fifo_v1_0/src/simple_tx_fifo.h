
#ifndef SIMPLE_TX_FIFO_H
#define SIMPLE_TX_FIFO_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xtime_l.h"
#include "xstatus.h"
#include "xil_assert.h"
#include "xil_types.h"

#define SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET 0
#define SIMPLE_TX_FIFO_DATA_IN_REG1_OFFSET 4
#define SIMPLE_TX_FIFO_OCCUPANCY_REG2_OFFSET 8
#define SIMPLE_TX_FIFO_STATUS_REG3_OFFSET 12

#define ESTXFIFO_FULL -1
#define ESTXFIFO_NOT_RDY -2

#define STXFIFO_MAX_US_WAIT 500
#define STXFIFO_POLL_VALID_MAX STXFIFO_MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)

/* control register bit masks */
#define STXFIFO_WRITE_EN_MASK  (1 << 0)
#define STXFIFO_CLK_EN_MASK    (1 << 1)
#define STXFIFO_RESET_MASK     (1 << 2)
#define STXFIFO_WR_COMMIT_MASK (1 << 3)

/* status register bit masks */
#define STXFIFO_BRAM_FULL_MASK  (1 << 0) 
#define STXFIFO_BRAM_EMPTY_MASK (1 << 1)
#define STXFIFO_BRAM_READY_MASK (1 << 2)

/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a SIMPLE_TX_FIFO register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the SIMPLE_TX_FIFOdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void SIMPLE_TX_FIFO_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define SIMPLE_TX_FIFO_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a SIMPLE_TX_FIFO register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the SIMPLE_TX_FIFO device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 SIMPLE_TX_FIFO_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define SIMPLE_TX_FIFO_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the SIMPLE_TX_FIFO instance to be worked on.
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
XStatus SIMPLE_TX_FIFO_Reg_SelfTest(void * baseaddr_p);

extern u32  STXFIFO_get_ctrl_reg(const u32 baseaddr);
extern void STXFIFO_en_write_en(const u32 baseaddr);
extern void STXFIFO_den_write_en(const u32 baseaddr);
extern void STXFIFO_en_clken(const u32 baseaddr);
extern void STXFIFO_den_clken(const u32 baseaddr);
extern void STXFIFO_en_reset(const u32 baseaddr);
extern void STXFIFO_den_reset(const u32 baseaddr);

extern u8 STXFIFO_poll_bram_full(const u32 baseaddr);
extern u8 STXFIFO_poll_bram_empty(const u32 baseaddr);
extern u8 STXFIFO_poll_bram_ready(const u32 baseaddr);
extern u32 STXFIFO_poll_occupancy(const u32 baseaddr);

extern u32  STXFIFO_write_data(const u32 baseaddr, const u32 datin);
extern void STXFIFO_write_commit(const u32 baseaddr);

extern void STXFIFO_disable_core(const u32 baseaddr);
extern void STXFIFO_init_core(const u32 baseaddr);

extern XTime STXFIFO_get_time(void);
extern XTime STXFIFO_elapsed_time_us(const XTime startTime);

#endif // SIMPLE_TX_FIFO_H
