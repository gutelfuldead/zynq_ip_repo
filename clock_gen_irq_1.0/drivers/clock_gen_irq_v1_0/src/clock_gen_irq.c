

/***************************** Include Files *******************************/
#include "clock_gen_irq.h"
#include "xbasic_types.h"

/************************** Function Definitions ***************************/

void CLOCK_GEN_IRQ_EnableInterrupt(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;
 /*
 * Enable all interrupt source from user logic.
 */
 CLOCK_GEN_IRQ_mWriteReg(baseaddr, 0x4, 0x1);
 /*
 * Set global interrupt enable.
 */
 CLOCK_GEN_IRQ_mWriteReg(baseaddr, 0x0, 0x1);
}
void CLOCK_GEN_IRQ_ACK(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;

 /*
 * ACK interrupts on TDMA_SLOT_GENERATOR.
 */
 CLOCK_GEN_IRQ_mWriteReg(baseaddr, 0xc, 0x1);
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
int Xclock_gen_CfgInitialize(Xclock_gen * InstancePtr, Xclock_gen_config * Config,
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
