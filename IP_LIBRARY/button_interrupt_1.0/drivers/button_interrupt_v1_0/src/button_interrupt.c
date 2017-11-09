

/***************************** Include Files *******************************/
#include "button_interrupt.h"
#include "xbasic_types.h"

/************************** Function Definitions ***************************/

void BUTTON_INTERRUPT_EnableInterrupt(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;
 /*
 * Enable all interrupt source from user logic.
 */
 BUTTON_INTERRUPT_mWriteReg(baseaddr, 0x4, 0x1);
 /*
 * Set global interrupt enable.
 */
 BUTTON_INTERRUPT_mWriteReg(baseaddr, 0x0, 0x1);
}
void BUTTON_INTERRUPT_ACK(void * baseaddr_p)
{
 Xuint32 baseaddr;
 baseaddr = (Xuint32) baseaddr_p;

 /*
 * ACK interrupts on BUTTON_INTERRUPTS.
 */
 BUTTON_INTERRUPT_mWriteReg(baseaddr, 0xc, 0x1);
}

/****************************************************************************/
/**
* Initialize the Xbtrn_intr instance provided by the caller based on the
* given configuration data.
*
* Nothing is done except to initialize the InstancePtr.
*
* @param	InstancePtr is a pointer to an Xbtn_intr instance. The memory the
*		pointer references must be pre-allocated by the caller. Further
*		calls to manipulate the driver through the Xbtn_intr API must be
*		made with this pointer.
* @param	Config is a reference to a structure containing information
*		about a specific BUTTON_INTERRUPT device. This function initializes an
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
int Xbtn_intr_CfgInitialize(Xbtn_intr * InstancePtr, Xbtn_intr_config * Config,
			UINTPTR EffectiveAddr)
{
	/* Assert arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/* Set some default values. */
	InstancePtr->BaseAddress = EffectiveAddr;

	InstancePtr->InterruptPresent = Config->InterruptPresent;
	// InstancePtr->IsDual = Config->IsDual;

	/*
	 * Indicate the instance is now ready to use, initialized without error
	 */
	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;
	return (XST_SUCCESS);
}
