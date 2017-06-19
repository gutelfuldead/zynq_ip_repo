
#ifndef AXI_MASTER_STREAM_FIFO_H
#define AXI_MASTER_STREAM_FIFO_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define AMSF_CONTROL_REG_OFFSET 0
#define AMSF_DIN_REG_OFFSET 4
#define AMSF_OCCUPANCY_REG_OFFSET 8
#define AMSF_STATUS_REG_OFFSET 12

#define EAMSF_FIFO_FULL -1

typedef enum _AMSF_CTRL_REG_MASK
{
	AMSF_WRITE_EN = (1 << 0),
	AMSF_CLKEN   = (1 << 1),
	AMSF_RESET    = (1 << 2)
};

typedef enum _AMSF_STATUS_REG_MASK
{
	AMSF_BRAM_FULL  = (1 << 0),
	AMSF_BRAM_EMPTY = (1 << 1)
};

/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_MASTER_STREAM_FIFO register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_MASTER_STREAM_FIFOdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void AXI_MASTER_STREAM_FIFO_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define AXI_MASTER_STREAM_FIFO_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_MASTER_STREAM_FIFO register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_MASTER_STREAM_FIFO device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 AXI_MASTER_STREAM_FIFO_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define AXI_MASTER_STREAM_FIFO_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the AXI_MASTER_STREAM_FIFO instance to be worked on.
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
XStatus AXI_MASTER_STREAM_FIFO_Reg_SelfTest(void * baseaddr_p);

extern u32  AMSF_get_ctrl_reg(const u32 baseaddr);
extern void AMSF_en_write_en(const u32 baseaddr);
extern void AMSF_den_write_en(const u32 baseaddr);
extern void AMSF_en_clken(const u32 baseaddr);
extern void AMSF_den_clken(const u32 baseaddr);
extern void AMSF_en_reset(const u32 baseaddr);
extern void AMSF_den_reset(const u32 baseaddr);

extern u8 AMSF_poll_bram_full(const u32 baseaddr);
extern u8 AMSF_poll_bram_empty(const u32 baseaddr);
extern u32 AMSF_poll_occupancy(const u32 baseaddr);

extern u32  AMSF_write_data(const u32 baseaddr, const u32 datin);

extern void AMSF_disable_core(const u32 baseaddr);
extern void AMSF_init_core(const u32 baseaddr);

#endif // AXI_MASTER_STREAM_FIFO_H
