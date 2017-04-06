
#ifndef TDMA_SLOT_GENERATOR_H
#define TDMA_SLOT_GENERATOR_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xil_assert.h"

#define TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET 0
#define TDMA_SLOT_GENERATOR_PULSE_TYPE_OFFSET 4
#define TDMA_SLOT_GENERATOR_S00_TDMA_DUTY_DEBUG_OFFSET 8
#define TDMA_SLOT_GENERATOR_S00_TDMA_DURATION_DEBUG_OFFSET 12

enum STATUS_REG_BITS{
  EN_BIT  = (1 << 0),
  RST_BIT = (1 << 1),
};

#define PULSE_TYPE_GPS  0x3f
#define PULSE_TYPE_NORM 0X2a

/* parameters matching the IP Cores settings for the GIC */
#define TDMA_SLOT_GENERATOR_EDGE_DETECTION 0x3  /* rising edge detection */

/**************************** Type Definitions *****************************/

typedef struct {
	u16 DeviceId;		/* Unique ID  of device */
	UINTPTR BaseAddress;	/* Device base address */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xtdma_slot_gen_config;

typedef struct {
	UINTPTR BaseAddress;	/* Device base address */
	u32 IsReady;		/* Device is initialized and ready */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xtdma_slot_gen;

/**
 *
 * Write a value to a TDMA_SLOT_GENERATOR register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the TDMA_SLOT_GENERATORdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void TDMA_SLOT_GENERATOR_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define TDMA_SLOT_GENERATOR_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a TDMA_SLOT_GENERATOR register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the TDMA_SLOT_GENERATOR device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 TDMA_SLOT_GENERATOR_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define TDMA_SLOT_GENERATOR_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the TDMA_SLOT_GENERATOR instance to be worked on.
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
XStatus TDMA_SLOT_GENERATOR_Reg_SelfTest(void * baseaddr_p);

/* interrupt functions */
extern void TDMA_SLOT_GENERATOR_EnableInterrupt(void * baseaddr_p);
extern void TDMA_SLOT_GENERATOR_ACK(void * baseaddr_p);
extern int Xtdma_slot_gen_CfgInitialize(Xtdma_slot_gen * InstancePtr, Xtdma_slot_gen_config * Config,
			UINTPTR EffectiveAddr);

/* general functions */
extern void tdma_slot_generator_enable(u32 TDMA_SLOT_GENERATOR_BASE_ADDR);
extern void tdma_slot_generator_soft_reset(u32 TDMA_SLOT_GENERATOR_BASE_ADDR);
extern void tdma_slot_generator_disable(u32 TDMA_SLOT_GENERATOR_BASE_ADDR);
extern uint32_t tdma_slot_generator_read_duty_cycle(u32 TDMA_SLOT_GENERATOR_BASE_ADDR);
extern uint32_t tdma_slot_generator_read_slot_len(u32 TDMA_SLOT_GENERATOR_BASE_ADDR);

#endif // TDMA_SLOT_GENERATOR_H
