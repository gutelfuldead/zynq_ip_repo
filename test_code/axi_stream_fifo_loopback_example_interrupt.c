#include "xparameters.h"
#include "xil_exception.h"
#include "xstreamer.h"
#include "xil_cache.h"
#include "xllfifo.h"
#include "xstatus.h"
#include "platform.h"
#include "xscugic.h"

#define VERBOSE

/** instance of the GIC */
static XScuGic Intc;
/** instance of fifo tx buffer */
static XLlFifo FifoInstance_tx;
/** instance of fifo rx buffer */
static XLlFifo FifoInstance_rx;

#define FIFO_TX_BASE_ADDRESS XPAR_AXI_FIFO_0_BASEADDR /**< rx fifo base address */
#define FIFO_RX_BASE_ADDRESS XPAR_AXI_FIFO_1_BASEADDR /**< tx fifo base address */
/** interrupt id for rx fifo */
#define FIFO_RX_IRQ XPAR_FABRIC_AXI_FIFO_MM_S_1_INTERRUPT_INTR

/* define GIC */
/** name of the interrupt controller */
#define INTC           XScuGic
/** used for the exception table */
#define INTC_HANDLER   XScuGic_InterruptHandler
/** GIC device ID */
#define INTC_DEVICE_ID XPAR_PS7_SCUGIC_0_DEVICE_ID
/** tx fifo device ID */
#define FIFO_TX_DEVICE_ID XPAR_AXI_FIFO_0_DEVICE_ID
/** rx fifo device ID */
#define FIFO_RX_DEVICE_ID XPAR_AXI_FIFO_1_DEVICE_ID
/** interrupt priority for tx and rd fifos */
#define FIFO_INTR_PRIORITY 0xA0
/** set interrupt level to be rising edge */
#define INTR_LEVEL 0x3

int setup_fifo_interrupts(INTC *IntcInstancePtr, XLlFifo *InstancePtr,
uint16_t FifoIntrId);
int load_fifo_tx(const uint32_t * const buf, const size_t len);
int fifo_enable(XLlFifo *InstancePtr, const uint16_t DeviceId);
void fifo_handler(XLlFifo *Fifo);
void fifo_recv_handler(XLlFifo *Fifo);
void fifo_error_handler(XLlFifo *InstancePtr, uint32_t Pending);

#define INTERRUPTED       1
#define INTERRUPT_CLEARED 0

#define MAX_SIZE 4091
#define WORD_SIZE sizeof(uint32_t) /**< size of fifo words in bytes */
volatile uint32_t rx_buf[MAX_SIZE];
volatile uint32_t tx_buf[MAX_SIZE];
volatile size_t   rx_buf_len;
volatile uint8_t  rx_recieved = INTERRUPT_CLEARED;

int main(void)
{
	printf("begin fifo test\n\r");
	/* enable tx fifo */
	int Status = fifo_enable(&FifoInstance_tx, FIFO_TX_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		printf("Failed to initialize TX_FIFO\n\r");
		return XST_FAILURE;
	}

	/* enable rx fifo */
	Status = fifo_enable(&FifoInstance_rx, FIFO_RX_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		printf("Failed to initialize RX_FIFO\n\r");
		return XST_FAILURE;
	}

	Status = setup_fifo_interrupts(&Intc, &FifoInstance_rx, FIFO_RX_IRQ);
	if (Status != XST_SUCCESS) {
		printf("Failed intr setup\r\n");
		return XST_FAILURE;
	}

	int i = 0;
	for(i = 0; i < MAX_SIZE; i++){
		tx_buf[i] = i;
	}
	int errcnt = 0;
	for(;;){
		errcnt = 0;
		load_fifo_tx(&tx_buf, MAX_SIZE);
		while(rx_recieved == INTERRUPT_CLEARED){}
		rx_recieved = INTERRUPT_CLEARED;
		for(i = 0; i < MAX_SIZE; i++){
			if(tx_buf[i] != rx_buf[i])
				errcnt++;
		}
		printf("errcnt = %d\n\r",errcnt);
	}

}


/**
  * function to enable TX and RX fifo instances
  * @param InstancePtr is the FIFO instance
  * @param DeviceId is the FIFO device ID
  * @param IRQ_ID is the interrupt ID provided in parameters.h
  */
int fifo_enable(XLlFifo *InstancePtr, const uint16_t DeviceId)
{
	XLlFifo_Config *Config;
	int Status;
	Status = XST_SUCCESS;

	/* Initialize the Device Configuration Interface driver */
	Config = XLlFfio_LookupConfig(DeviceId);
	if (!Config) {
		printf("No config found for %d\r\n", DeviceId);
		return XST_FAILURE;
	}

	/*
	 * This is where the virtual address would be used, this example
	 * uses physical address.
	 */
	Status = XLlFifo_CfgInitialize(InstancePtr, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		printf("fifo initialization failed\n\r");
		return Status;
	}


	/* Check for the Reset value */
	Status = XLlFifo_Status(InstancePtr);
	XLlFifo_IntClear(InstancePtr,0xffffffff);
	Status = XLlFifo_Status(InstancePtr);
	if(Status != 0x0) {
		printf("\n ERROR : Reset value of ISR : 0x%x\t"
		       "Expected : 0x0\n\r",
		       (int)XLlFifo_Status(InstancePtr));
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/**
  * Checks if error occurs from Fifo
  * @param InstancePtr points to the specific Fifo
  * @param Pending the interrupt to check
  */
void fifo_error_handler(XLlFifo *InstancePtr, uint32_t Pending)
{
	if (Pending & XLLF_INT_RPURE_MASK) {
		#ifdef VERBOSE
		printf("error : receive under read\n\r");
		#endif
		XLlFifo_RxReset(InstancePtr);
	} else if (Pending & XLLF_INT_RPORE_MASK) {
		#ifdef VERBOSE
		printf("error : receive over read\n\r");
		#endif
		XLlFifo_RxReset(InstancePtr);
	} else if(Pending & XLLF_INT_RPUE_MASK) {
		#ifdef VERBOSE
		printf("error : receive under run (empty)\n\r");
		#endif
		XLlFifo_RxReset(InstancePtr);
	} else if (Pending & XLLF_INT_TPOE_MASK) {
		#ifdef VERBOSE
		printf("error : transmit over read\n\r");
		#endif
		XLlFifo_TxReset(InstancePtr);
	} else if (Pending & XLLF_INT_TSE_MASK) {
		#ifdef VERBOSE
		printf("error : transmit length mismatch\n\r");
		#endif
	}
}

/**
  * handler used for the fifo when it has data to send ot PS
  * @param InstancePtr points to the specific fifo
  */
void fifo_recv_handler(XLlFifo *InstancePtr)
{
	int i;
	uint32_t RxWord;
	static uint32_t ReceiveLength;

	/* Read Recieve Length */
	ReceiveLength = (XLlFifo_iRxGetLen(InstancePtr))/WORD_SIZE;
	printf("received %d bytes, %d words\n\r", (int)ReceiveLength*WORD_SIZE, ReceiveLength);
	for (i=0; i < ReceiveLength; i++) {
		rx_buf[i] = XLlFifo_RxGetWord(InstancePtr);
	}
	rx_buf_len = ReceiveLength;
	rx_recieved = INTERRUPTED;
	return;
}

/**
  * Checks the interrupt and calls the appropraite routines
  * @param InstancePtr the instance that called the interrupt
  */
void fifo_handler(XLlFifo *InstancePtr)
{
	uint32_t Pending;

	Pending = XLlFifo_IntPending(InstancePtr);
	while (Pending) {
		if (Pending & XLLF_INT_RC_MASK) {
			/* receive complete */
			fifo_recv_handler(InstancePtr);
			XLlFifo_IntClear(InstancePtr, XLLF_INT_RC_MASK);
		} else if (Pending & XLLF_INT_TC_MASK) {
			/* transmit complete */
			XLlFifo_IntClear(InstancePtr, XLLF_INT_TC_MASK);
		} else if (Pending & XLLF_INT_ERROR_MASK) {
			/* Error status */
			fifo_error_handler(InstancePtr, Pending);
			XLlFifo_IntClear(InstancePtr, XLLF_INT_ERROR_MASK);
		} else if(Pending & XLLF_INT_RFPF_MASK) {
			#ifdef VERBOSE
			printf("RX programmable full interrupt\n\r");
			#endif
			XLlFifo_IntClear(InstancePtr,XLLF_INT_RFPF_MASK);
		} else if (Pending & XLLF_INT_RFPE_MASK) {
			#ifdef VERBOSE
			printf("RX programmable empty interrupt\n\r");
			#endif
			XLlFifo_IntClear(InstancePtr,XLLF_INT_RFPE_MASK);
		}
		else {
			XLlFifo_IntClear(InstancePtr, Pending);
		}
		Pending = XLlFifo_IntPending(InstancePtr);
	}
}

/**
 * enables interrupt for AXI-Stream FIFO IP
 * @param  IntcInstancePtr instance of interrupt controller to setup
 * @param  InstancePtr     instance of fifo to setup
 * @param  FifoIntrId      interrupt ID of fifo InstancePtr
 * @return                 XST_SUCCESS | XST_FAILURE
 */
int setup_fifo_interrupts(INTC *IntcInstancePtr, XLlFifo *InstancePtr,
                          uint16_t FifoIntrId)
{

	int Status;
	XScuGic_Config *IntcConfig;

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
	                               IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, FifoIntrId, FIFO_INTR_PRIORITY, INTR_LEVEL);

	/*
	 * Connect the device driver handler that will be called when an
	 * interrupt for the device occurs, the handler defined above performs
	 * the specific interrupt processing for the device.
	 */
	Status = XScuGic_Connect(IntcInstancePtr, FifoIntrId,
	                         (Xil_InterruptHandler)fifo_handler,
	                         InstancePtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	XScuGic_Enable(IntcInstancePtr, FifoIntrId);

	/*
	 * Initialize the exception table.
	 */
	Xil_ExceptionInit();

	/*
	 * Register the interrupt controller handler with the exception table.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
	                             (Xil_ExceptionHandler)INTC_HANDLER,
	                             (void *)IntcInstancePtr);

	/*
	 * Enable exceptions.
	 */
	Xil_ExceptionEnable();

	XLlFifo_IntEnable(InstancePtr, XLLF_INT_ALL_MASK);


	return XST_SUCCESS;
}

/**
 * set transmit message in buffer and enable G_TX_RDY bit
 * @return     0
 */
int load_fifo_tx(const uint32_t * const buf, const size_t len)
{
	int i;

	/* flush the fifo */
	XLlFifo_TxReset(&FifoInstance_tx);

	for(i=0; i < len; i++) {
		/* Writing into the FIFO Transmit Port Buffer */
		if( XLlFifo_iTxVacancy(&FifoInstance_tx) ) {
			XLlFifo_TxPutWord(&FifoInstance_tx,
			                  *(buf + i));
		}
	}

	/* Start Transmission by writing transmission length into the TLR */
	XLlFifo_iTxSetLen(&FifoInstance_tx, (len * WORD_SIZE));

	printf("Sent %d bytes, %d words\n\r",(int)len*WORD_SIZE, (int)len);

	/* Transmission Complete */
	return XST_SUCCESS;
}
