
#ifndef BUTTON_INTERRUPT_H
#define BUTTON_INTERRUPT_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xil_assert.h"

#define BUTTON_INTERRUPT_S00_AXI_SLV_REG0_OFFSET 0
#define BUTTON_INTERRUPT_S00_AXI_SLV_REG1_OFFSET 4
#define BUTTON_INTERRUPT_S00_AXI_SLV_REG2_OFFSET 8
#define BUTTON_INTERRUPT_S00_AXI_SLV_REG3_OFFSET 12


/**************************** Type Definitions *****************************/

/**
 * This typedef contains configuration information for the device.
 */
typedef struct {
	u16 DeviceId;		/* Unique ID  of device */
	UINTPTR BaseAddress;	/* Device base address */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xbtn_intr_config;

/**
 * The Xbtn_intr driver instance data. The user is required to allocate a
 * variable of this type for every device in the system. A pointer
 * to a variable of this type is then passed to the driver API functions.
 */
typedef struct {
	UINTPTR BaseAddress;	/* Device base address */
	u32 IsReady;		/* Device is initialized and ready */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xbtn_intr;

/**
 *
 * Write a value to a BUTTON_INTERRUPT register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the BUTTON_INTERRUPTdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void BUTTON_INTERRUPT_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define BUTTON_INTERRUPT_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a BUTTON_INTERRUPT register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the BUTTON_INTERRUPT device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 BUTTON_INTERRUPT_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define BUTTON_INTERRUPT_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the BUTTON_INTERRUPT instance to be worked on.
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
XStatus BUTTON_INTERRUPT_Reg_SelfTest(void * baseaddr_p);

/************************* Function Declarations ***************************/
extern void BUTTON_INTERRUPT_EnableInterrupt(void * baseaddr_p);
extern void BUTTON_INTERRUPT_ACK(void * baseaddr_p);
extern int Xbtn_intr_CfgInitialize(Xbtn_intr * InstancePtr, Xbtn_intr_config * Config,
			UINTPTR EffectiveAddr);

#endif // BUTTON_INTERRUPT_H
