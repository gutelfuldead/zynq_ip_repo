#include "xparameters.h"
#include "xil_exception.h"
#include "xstatus.h"
#include "stdio.h"
#include "stdlib.h"
#include "simple_rx_fifo.h"
#include "simple_tx_fifo.h"
#include "xscugic.h"
#include "platform.h"

#define SHOW_OCC
//#define V

#define RX_FIFO_ADDR     0X43C00000
#define RX_FIFO_IRQ_ADDR 0X43C10000
#define TX_FIFO_ADDR     0X43C20000

#define MAX_PACKETS 10
#define WORDS_PER_PACKET 20

#define INTERRUPTED       1
#define INTERRUPT_CLEAR   0

#define INTC_DEVICE_ID         XPAR_PS7_SCUGIC_0_DEVICE_ID
#define RX_FIFO_INTERRUPT_ID   XPAR_FABRIC_SIMPLE_RX_FIFO_0_IRQ_INTR
#define RXFIFO_INT_PRIORITY     0xA0
static XScuGic           Intc;
static Xsrxfifo          RXFIFO_INST;
volatile int RX_FIFO_IRQ = INTERRUPT_CLEAR;


int tx(const int nwords);
int rx(int * const errcnt, int * const nbytes);
int generic_interrupt_setup(XScuGic * IntController, Xil_ExceptionHandler handler, uint32_t Int_Id, uint8_t Priority, uint8_t Trigger, void *CallBackRef, void *baseaddr);
void srxfifo_handler();

int main(void)
{
	printf("begin fifo test\n\r");
	STXFIFO_init_core(TX_FIFO_ADDR);
	SRXFIFO_init_core(RX_FIFO_ADDR);

	int status = generic_interrupt_setup(&Intc, srxfifo_handler, (uint32_t)RX_FIFO_INTERRUPT_ID, (uint8_t)RXFIFO_INT_PRIORITY,
		(uint8_t)SRXFIFO_EDGE_DETECTION, &RXFIFO_INST, (void *)RX_FIFO_IRQ_ADDR);
    if(status == XST_FAILURE){
    	printf("Failure initializing RX FIFO Interrupts\n\r");
    }
    else{
	    printf("Successfully initialized RX FIFO Interrupts\n\r");
	    SRXFIFO_EnableInterrupt((void *)RX_FIFO_IRQ_ADDR);
    }

	int packets, nerrors, nwords;
	for(packets = 1; packets < MAX_PACKETS; packets++){
		int words = packets*WORDS_PER_PACKET;
		printf("Sent %d words to tx fifo\n\r",words);
		SRXFIFO_write_interrupt_level(RX_FIFO_ADDR, (uint32_t)words);
		status = tx(words);
		if(status != XST_SUCCESS)
			return XST_FAILURE;
		while(RX_FIFO_IRQ == INTERRUPT_CLEAR){
#ifdef SHOW_OCC
		printf("tx fifo occ = %d : rx fifo occ = %d\n\r", (int)STXFIFO_poll_occupancy(TX_FIFO_ADDR),(int)SRXFIFO_poll_occupancy(RX_FIFO_ADDR));
#endif
		}
		RX_FIFO_IRQ = INTERRUPT_CLEAR;
		status = rx(&nerrors, &nwords);
		if(status != XST_SUCCESS){
			return XST_FAILURE;
		}
		printf("Received %d words w/ %d errors\n\r",nwords,nerrors);
		if(nerrors > 0)
			return XST_FAILURE;
		SRXFIFO_init_core(RX_FIFO_ADDR);
	}

	/* reset core before interrupt level is reached */
	SRXFIFO_write_interrupt_level(RX_FIFO_ADDR, (uint32_t)200);
	status = tx(100);
	sleep(1);
	SRXFIFO_init_core(RX_FIFO_ADDR);
	SRXFIFO_write_interrupt_level(RX_FIFO_ADDR, (uint32_t)200);
	status = tx(200);
	while(RX_FIFO_IRQ == INTERRUPT_CLEAR){
#ifdef SHOW_OCC
		printf("tx fifo occ = %d : rx fifo occ = %d\n\r", (int)STXFIFO_poll_occupancy(TX_FIFO_ADDR),(int)SRXFIFO_poll_occupancy(RX_FIFO_ADDR));
#endif
		}
		RX_FIFO_IRQ = INTERRUPT_CLEAR;
		status = rx(&nerrors, &nwords);
		if(status != XST_SUCCESS){
			return XST_FAILURE;
		}
		printf("Received %d words w/ %d errors\n\r",nwords,nerrors);
		if(nerrors > 0)
			return XST_FAILURE;

}

tx(const int nwords)
{
	int i, status;
	for(i = 1; i <= nwords; i++){
		uint32_t tmp = i;
		status = STXFIFO_write_data(TX_FIFO_ADDR, tmp);
		if(status != XST_SUCCESS){
			printf("Error writing to tx fifo\n\r");
			return XST_FAILURE;
		}
	}
	STXFIFO_write_commit(TX_FIFO_ADDR);
	return XST_SUCCESS;
}

rx(int * const errcnt, int * const nbytes)
{
	int i, status;
	int errors = 0;
	u32 occ = SRXFIFO_poll_occupancy(RX_FIFO_ADDR);
	printf("rx occ = %lu\n\r",SRXFIFO_poll_occupancy(RX_FIFO_ADDR));
	for(i = 1; i <= occ; i++){
		uint32_t tmp;
		status = SRXFIFO_read_data(RX_FIFO_ADDR, &tmp);
		if(status != XST_SUCCESS){
			printf("Error reading from rx fifo: %s\n\r",
				status == ESRXFIFO_EMPTY ? "Fifo empty" : "valid not asserted");
			return XST_FAILURE;
		}
		else if(tmp != i)
			errors++;
		#ifdef V
		printf("tx[%03d] = %03d : rx[%03d] = %03d%s\n\r",
			i,i,i,tmp, tmp != i ? "-- ERROR" : "");
		#endif
	}
	*errcnt = errors;
	*nbytes = occ;
	return XST_SUCCESS;
}

/**
 * Exception handler for RX FIFO
 */
void srxfifo_handler()
{
	RX_FIFO_IRQ = INTERRUPTED;
	#ifdef V
		printf("Simple RX FIFO Interrupt at %lu occupancy\n\r",SRXFIFO_poll_occupancy(RX_FIFO_ADDR));
	#endif
	SRXFIFO_ACK((void *)RX_FIFO_IRQ_ADDR);
}

/**
 * Generic Interrupt Handler Setup
 * @param  IntC        Interrupt Controller Struct
 * @param  handler     Interrupt Handler Routine
 * @param  Int_Id      Interrupt ID Value
 * @param  Priority    Interrupt Priority Value
 * @param  Trigger     Interrupt Edge Detection Trigger
 * @param  CallBackRef Structure specific to Interrupt Source (IE the instance pointer of the connecting driver)
 * @param  baseaddr    The base address to the driver interrupt
 * @return             XST_SUCCESS or XST_FAILURE
 */
int generic_interrupt_setup(XScuGic * IntController, Xil_ExceptionHandler handler, uint32_t Int_Id, uint8_t Priority, uint8_t Trigger, void *CallBackRef, void *baseaddr)
{
	int 	xstatus;
	// doesnt work
	XScuGic	*IntcInstancePtr = IntController;
	// works
//	XScuGic	*IntcInstancePtr = &Intc;

	XScuGic_Config *IntcConfig;

	/* Initialize the interrupt controller driver so that it is ready to use. */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	/* IntcInstancePtr Pointer to ScuGic instance */
	xstatus = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
	                                IntcConfig->CpuBaseAddress);
	if (xstatus != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Initialize the exception table and register the interrupt */
	/* controller handler with the exception table */
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
	                             (Xil_ExceptionHandler)XScuGic_InterruptHandler, IntcInstancePtr);

	/* Enable non-critical exceptions */
	Xil_ExceptionEnable();
	XScuGic_SetPriorityTriggerType(IntcInstancePtr, Int_Id, Priority, Trigger);

	/* Connect the interrupt handler that will be called when an */
	/* interrupt occurs for the device. */
	xstatus = XScuGic_Connect(IntcInstancePtr, Int_Id, (Xil_ExceptionHandler)handler, CallBackRef);
	if (xstatus != XST_SUCCESS) {
		return xstatus;
	}

	//  Enable the interrupt for the CustomIp device.
	XScuGic_Enable(IntcInstancePtr, Int_Id);

	return XST_SUCCESS;
}
