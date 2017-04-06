
#ifndef CLOCK_GEN_IRQ_H
#define CLOCK_GEN_IRQ_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xil_assert.h"

#define CLOCK_GEN_IRQ_CONTROL_REG_OFFSET 0
#define EN_BIT (1 << 0)
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG1_OFFSET 4
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG2_OFFSET 8
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG3_OFFSET 12
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG4_OFFSET 16
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG5_OFFSET 20
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG6_OFFSET 24
#define CLOCK_GEN_IRQ_S00_AXI_SLV_REG7_OFFSET 28


/**************************** Type Definitions *****************************/

typedef struct {
	u16 DeviceId;		/* Unique ID  of device */
	UINTPTR BaseAddress;	/* Device base address */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xclock_gen_config;

typedef struct {
	UINTPTR BaseAddress;	/* Device base address */
	u32 IsReady;		/* Device is initialized and ready */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xclock_gen;

/**
 *
 * Write a value to a CLOCK_GEN_IRQ register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the CLOCK_GEN_IRQdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void CLOCK_GEN_IRQ_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define CLOCK_GEN_IRQ_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a CLOCK_GEN_IRQ register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the CLOCK_GEN_IRQ device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 CLOCK_GEN_IRQ_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define CLOCK_GEN_IRQ_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the CLOCK_GEN_IRQ instance to be worked on.
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
XStatus CLOCK_GEN_IRQ_Reg_SelfTest(void * baseaddr_p);

extern void CLOCK_GEN_IRQ_EnableInterrupt(void * baseaddr_p);
extern void CLOCK_GEN_IRQ_ACK(void * baseaddr_p);
extern int Xclock_gen_CfgInitialize(Xclock_gen * InstancePtr, Xclock_gen_config * Config,
			UINTPTR EffectiveAddr);

#endif // CLOCK_GEN_IRQ_H
