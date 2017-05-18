
#ifndef AXI_BRAM_FIFO_CONTROLLER_H
#define AXI_BRAM_FIFO_CONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

enum SLV_REGISTERS{
	AXI_BRAM_FIFO_CONTROLLER_REG                = 0,
	AXI_BRAM_FIFO_CONTROLLER_DOUT_REG           = 4,
	AXI_BRAM_FIFO_CONTROLLER_OUTPUT_CONTROL_REG = 8,
	AXI_BRAM_FIFO_CONTROLLER_DIN_REG            = 12
};

enum FIFO_CONTROL_REG_BITS{
	WRITE_EN = (1 << 0),
	READ_EN  = (1 << 1),
	RESET    = (1 << 2),
	CLKEN    = (1 << 3)
};

enum FIFO_OUTPUT_CONTROL_REG_BITS{
	DOUT_VALID = (1 << 0),
	BRAM_FULL  = (1 << 1),
	BRAM_EMPTY = (1 << 2)
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

extern u32 AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_en_write_en(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_den_write_en(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_en_clken(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_den_clken(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_en_read_en(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_den_read_en(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_en_reset(const u32 baseaddr);
extern void AXI_BRAM_FIFO_CONTROLLER_den_reset(const u32 baseaddr);

extern u8 AXI_BRAM_FIFO_CONTROLLER_poll_dout_valid(const u32 baseaddr);
extern u8 AXI_BRAM_FIFO_CONTROLLER_poll_bram_full(const u32 baseaddr);
extern u8 AXI_BRAM_FIFO_CONTROLLER_poll_bram_empty(const u32 baseaddr);

extern u32 AXI_BRAM_FIFO_CONTROLLER_write_data(const u32 baseaddr, const u32 dat);
extern u32 AXI_BRAM_FIFO_CONTROLLER_read_data(const u32 baseaddr, u32 *datout);

#endif // AXI_BRAM_FIFO_CONTROLLER_H
