
#ifndef PMOD_RS485_CONTROLLER_H
#define PMOD_RS485_CONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET 0
#define PMOD_RS485_CONTROLLER_S00_AXI_SLV_REG1_OFFSET 4
#define PMOD_RS485_CONTROLLER_S00_AXI_SLV_REG2_OFFSET 8
#define PMOD_RS485_CONTROLLER_S00_AXI_SLV_REG3_OFFSET 12

#define RE (0 << 0)
#define DE (1 << 1)
#define EN (1 << 2)


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a PMOD_RS485_CONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the PMOD_RS485_CONTROLLERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void PMOD_RS485_CONTROLLER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define PMOD_RS485_CONTROLLER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a PMOD_RS485_CONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the PMOD_RS485_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 PMOD_RS485_CONTROLLER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define PMOD_RS485_CONTROLLER_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the PMOD_RS485_CONTROLLER instance to be worked on.
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
XStatus PMOD_RS485_CONTROLLER_Reg_SelfTest(void * baseaddr_p);

extern void pmod_rs485_controller_enable(const int baseaddr);
extern void pmod_rs485_controller_disable(const int baseaddr);
extern void pmod_rs485_controller_enable_rd(const int baseaddr);
extern void pmod_rs485_controller_disable_rd(const int baseaddr);
extern void pmod_rs485_controller_enable_wr(const int baseaddr);
extern void pmod_rs485_controller_disable_wr(const int baseaddr);
extern u32  pmod_rs485_controller_get_control_reg(const int baseaddr);
extern void pmod_rs485_controller_clear_control_reg(const int baseaddr);


#endif // PMOD_RS485_CONTROLLER_H
