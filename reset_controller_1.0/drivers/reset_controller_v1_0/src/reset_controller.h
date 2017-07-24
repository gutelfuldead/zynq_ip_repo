
#ifndef RESET_CONTROLLER_H
#define RESET_CONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET 0
#define RESET_CONTROLLER_S00_AXI_SLV_REG1_OFFSET 4
#define RESET_CONTROLLER_S00_AXI_SLV_REG2_OFFSET 8
#define RESET_CONTROLLER_S00_AXI_SLV_REG3_OFFSET 12

typedef enum _RST_CTRL_REG_MASK
{
	RST_CTRL_SYS_RESET = (1 << 0),
	RST_CTRL_VITERBI_RESET = (1 << 1)
};


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a RESET_CONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the RESET_CONTROLLERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void RESET_CONTROLLER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define RESET_CONTROLLER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a RESET_CONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the RESET_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 RESET_CONTROLLER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define RESET_CONTROLLER_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the RESET_CONTROLLER instance to be worked on.
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
XStatus RESET_CONTROLLER_Reg_SelfTest(void * baseaddr_p);

extern u32  RST_CTRL_get_ctrl_reg(const u32 baseaddr);
extern void RST_CTRL_system(const u32 baseaddr);
extern void RST_CTRL_viterbi(const u32 baseaddr);

#endif // RESET_CONTROLLER_H
