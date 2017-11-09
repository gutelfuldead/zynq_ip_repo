

/***************************** Include Files *******************************/
#include "tdma_slot_generator.h"
#include "xbasic_types.h"

/************************** Function Definitions ***************************/

/**
  * enables the interrupt settings in the IP Core
  * @param baseaddr_p pointer to the core's interrupt AXI base address
  */
void TDMA_SLOT_GENERATOR_EnableInterrupt(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;
 /*
 * Enable all interrupt source from user logic.
 */
 TDMA_SLOT_GENERATOR_mWriteReg(baseaddr, 0x4, 0x1);
 /*
 * Set global interrupt enable.
 */
 TDMA_SLOT_GENERATOR_mWriteReg(baseaddr, 0x0, 0x1);
}

/**
  * acknowledges and clears an interrupt in the core
  * @param baseaddr_p pointer to the core's interrupt AXI base address
  */
void TDMA_SLOT_GENERATOR_ACK(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;

 /*
 * ACK interrupts on TDMA_SLOT_GENERATOR.
 */
 TDMA_SLOT_GENERATOR_mWriteReg(baseaddr, 0xc, 0x1);
}

/****************************************************************************/
/**
* Initialize the Xtdma_slot_gen instance provided by the caller based on the
* given configuration data.
*
* Nothing is done except to initialize the InstancePtr.
*
* @param	InstancePtr is a pointer to an Xtdma_slot_gen instance. The memory the
*		pointer references must be pre-allocated by the caller. Further
*		calls to manipulate the driver through the Xbtn_intr API must be
*		made with this pointer.
* @param	Config is a reference to a structure containing information
*		about a specific TDMA_SLOT_GEN device. This function initializes an
*		InstancePtr object for a specific device specified by the
*		contents of Config. This function can initialize multiple
*		instance objects with the use of multiple calls giving different
*		Config information on each call.
* @param 	EffectiveAddr is the device base address in the virtual memory
*		address space. The caller is responsible for keeping the address
*		mapping from EffectiveAddr to the device physical base address
*		unchanged once this function is invoked. Unexpected errors may
*		occur if the address mapping changes after this function is
*		called. If address translation is not used, use
*		Config->BaseAddress for this parameters, passing the physical
*		address instead.
*
* @return
* 		- XST_SUCCESS if the initialization is successfull.
*
* @note		None.
*
*****************************************************************************/
int Xtdma_slot_gen_CfgInitialize(Xtdma_slot_gen * InstancePtr, Xtdma_slot_gen_config * Config,
			UINTPTR EffectiveAddr)
{
	/* Assert arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/* Set some default values. */
	InstancePtr->BaseAddress = EffectiveAddr;

	InstancePtr->InterruptPresent = Config->InterruptPresent;

	/*
	 * Indicate the instance is now ready to use, initialized without error
	 */
	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;
	return (XST_SUCCESS);
}

/******************************************************************************/
/*					  tdma_slot_generator_v2 functions                        */
/******************************************************************************/

/**
 * enables tdma_slot_generator_v2
 */
void tdma_slot_generator_enable(u32 TDMA_SLOT_GENERATOR_BASE_ADDR)
{
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
  return;
}

/**
 * performs soft reset and enables tdma_slot_generator_v2
 */
void tdma_slot_generator_soft_reset(u32 TDMA_SLOT_GENERATOR_BASE_ADDR)
{
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | RST_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
  return;
}

/**
 * disables tdma_slot_generator_v2
 */
void tdma_slot_generator_disable(u32 TDMA_SLOT_GENERATOR_BASE_ADDR)
{
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, 0x0);
  return;
}

/**
 * reads hardware defined duty cycle of output pulse
 * @return duty cycle of output pulse
 */
uint32_t tdma_slot_generator_read_duty_cycle(u32 TDMA_SLOT_GENERATOR_BASE_ADDR)
{
	return TDMA_SLOT_GENERATOR_mReadReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
			TDMA_SLOT_GENERATOR_S00_TDMA_DUTY_DEBUG_OFFSET);
}

/**
 * reads hardware defined tdma slot length
 * @return slot length in milliseconds
 */
uint32_t tdma_slot_generator_read_slot_len(u32 TDMA_SLOT_GENERATOR_BASE_ADDR)
{
	return TDMA_SLOT_GENERATOR_mReadReg(TDMA_SLOT_GENERATOR_BASE_ADDR,
			TDMA_SLOT_GENERATOR_S00_TDMA_DURATION_DEBUG_OFFSET);
}