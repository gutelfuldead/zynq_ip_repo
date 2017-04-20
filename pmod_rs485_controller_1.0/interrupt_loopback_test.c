#include "xparameters.h"
#include "xplatform_info.h"
#include "xuartps.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "pmod_rs485_controller.h"
#include "xil_printf.h"

#define UART_DEVICE_ID		XPAR_XUARTPS_0_DEVICE_ID
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define UART_INT_IRQ_ID		XPAR_XUARTPS_0_INTR
#define PMOD_RS485_BASE_ADDR			0x43C00000
#define TEST_BUFFER_SIZE	10

/**************************** Type Definitions ******************************/


/************************** Function Prototypes *****************************/

int UartPsIntrExample(XScuGic *IntcInstPtr, XUartPs *UartInstPtr,
			u16 DeviceId, u16 UartIntrId);

static int SetupInterruptSystem(XScuGic *IntcInstancePtr,
				XUartPs *UartInstancePtr,
				u16 UartIntrId);

void Handler(void *CallBackRef, u32 Event, unsigned int EventData);


/************************** Variable Definitions ***************************/

XUartPs UartPs	;		/* Instance of the UART Device */
XScuGic InterruptController;	/* Instance of the Interrupt Controller */

/*
 * The following buffers are used in this example to send and receive data
 * with the UART.
 */
static u8 SendBuffer[TEST_BUFFER_SIZE];	/* Buffer for Transmitting Data */
static u8 RecvBuffer[TEST_BUFFER_SIZE];	/* Buffer for Receiving Data */

/*
 * The following counters are used to determine when the entire buffer has
 * been sent and received.
 */
volatile int TotalReceivedCount;
volatile int TotalSentCount;
volatile int RX_FLAG = 1;

int TotalErrorCount;

/**************************************************************************/
/**
*
* Main function to call the Uart interrupt example.
*
* @param	None
*
* @return	XST_SUCCESS if successful, XST_FAILURE if unsuccessful
*
* @note		None
*
**************************************************************************/
int main(void)
{
	int Status;
	/* enable pmod_rs485_controller ip core */
	pmod_rs485_controller_enable(PMOD_RS485_BASE_ADDR);
	pmod_rs485_controller_enable_wr(PMOD_RS485_BASE_ADDR);
	pmod_rs485_controller_enable_rd(PMOD_RS485_BASE_ADDR);

	/* Run the UartPs Interrupt example, specify the the Device ID */
	Status = UartPsIntrExample(&InterruptController, &UartPs,
				UART_DEVICE_ID, UART_INT_IRQ_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("UART Interrupt Example Test Failed\r\n");
		return XST_FAILURE;
	}

	xil_printf("Successfully ran UART Interrupt Example Test\r\n");
	return XST_SUCCESS;
}

/**************************************************************************/
/**
*
* This function does a minimal test on the UartPS device and driver as a
* design example. The purpose of this function is to illustrate
* how to use the XUartPs driver.
*
* This function sends data and expects to receive the same data through the
* device using the local loopback mode.
*
* This function uses interrupt mode of the device.
*
* @param	IntcInstPtr is a pointer to the instance of the Scu Gic driver.
* @param	UartInstPtr is a pointer to the instance of the UART driver
*		which is going to be connected to the interrupt controller.
* @param	DeviceId is the device Id of the UART device and is typically
*		XPAR_<UARTPS_instance>_DEVICE_ID value from xparameters.h.
* @param	UartIntrId is the interrupt Id and is typically
*		XPAR_<UARTPS_instance>_INTR value from xparameters.h.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note
*
* This function contains an infinite loop such that if interrupts are not
* working it may never return.
*
**************************************************************************/
int UartPsIntrExample(XScuGic *IntcInstPtr, XUartPs *UartInstPtr,
			u16 DeviceId, u16 UartIntrId)
{
	int Status;
	XUartPs_Config *Config;
	int i;
	u32 IntrMask;
	int BadByteCount = 0;

	/*
	 * Initialize the UART driver so that it's ready to use
	 * Look up the configuration in the config table, then initialize it.
	 */
	Config = XUartPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}

	UartInstPtr->BaudRate = 115200;
	Status = XUartPs_CfgInitialize(UartInstPtr, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Check hardware build */
	Status = XUartPs_SelfTest(UartInstPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the UART to the interrupt subsystem such that interrupts
	 * can occur. This function is application specific.
	 */
	Status = SetupInterruptSystem(IntcInstPtr, UartInstPtr, UartIntrId);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Setup the handlers for the UART that will be called from the
	 * interrupt context when data has been sent and received, specify
	 * a pointer to the UART driver instance as the callback reference
	 * so the handlers are able to access the instance data
	 */
	XUartPs_SetHandler(UartInstPtr, (XUartPs_Handler)Handler, UartInstPtr);

	/*
	 * Enable the interrupt of the UART so interrupts will occur, setup
	 * a local loopback so data that is sent will be received.
	 */
	IntrMask =
		XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY | XUARTPS_IXR_FRAMING |
		XUARTPS_IXR_OVER | XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_RXFULL |
		XUARTPS_IXR_RXOVR;

	XUartPs_SetInterruptMask(UartInstPtr, IntrMask);
	XUartPs_SetOperMode(UartInstPtr, XUARTPS_OPER_MODE_NORMAL);

	/*
	 * Set the receiver timeout. If it is not set, and the last few bytes
	 * of data do not trigger the over-water or full interrupt, the bytes
	 * will not be received. By default it is disabled.
	 *
	 * The setting of 8 will timeout after 8 x 4 = 32 character times.
	 * Increase the time out value if baud rate is high, decrease it if
	 * baud rate is low.
	 */
	XUartPs_SetRecvTimeout(UartInstPtr, 200);


	/*
	 * Initialize the send buffer bytes with a pattern and the
	 * the receive buffer bytes to zero to allow the receive data to be
	 * verified
	 */
	for (i = 0; i < TEST_BUFFER_SIZE; i++) {
		SendBuffer[i] = (i % 26) + 'A';
		RecvBuffer[i] = 0;
	}

	/*
	 * Start receiving data before sending it since there is a loopback,
	 * ignoring the number of bytes received as the return value since we
	 * know it will be zero
	 */
//	XUartPs_Recv(UartInstPtr, RecvBuffer, TEST_BUFFER_SIZE);

	/*
	 * Send the buffer using the UART and ignore the number of bytes sent
	 * as the return value since we are using it in interrupt mode.
	 */
	for(;;){
		if(RX_FLAG == 1){
		XUartPs_Send(UartInstPtr, SendBuffer, TEST_BUFFER_SIZE);
		RX_FLAG = 0;
		}
	}
	/*
	 * Wait for the entire buffer to be received, letting the interrupt
	 * processing work in the background, this function may get locked
	 * up in this loop if the interrupts are not working correctly.
	 */
	while (1) {
		if ((TotalSentCount == TEST_BUFFER_SIZE) &&
		    (TotalReceivedCount == TEST_BUFFER_SIZE)) {
			break;
		}
	}

	/* Verify the entire receive buffer was successfully received */
	for (i = 0; i < TEST_BUFFER_SIZE; i++) {
		if (RecvBuffer[i] != SendBuffer[i]) {
			BadByteCount++;
		}
	}


	/* If any bytes were not correct, return an error */
	if (BadByteCount != 0) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/**************************************************************************/
/**
*
* This function is the handler which performs processing to handle data events
* from the device.  It is called from an interrupt context. so the amount of
* processing should be minimal.
*
* This handler provides an example of how to handle data for the device and
* is application specific.
*
* @param	CallBackRef contains a callback reference from the driver,
*		in this case it is the instance pointer for the XUartPs driver.
* @param	Event contains the specific kind of event that has occurred.
* @param	EventData contains the number of bytes sent or received for sent
*		and receive events.
*
* @return	None.
*
* @note		None.
*
***************************************************************************/
void Handler(void *CallBackRef, u32 Event, unsigned int EventData)
{
//	static int i = 0;

	/* All of the data has been sent */
	if (Event == XUARTPS_EVENT_SENT_DATA) {
		xil_printf("Data Sent\n\r");
		TotalSentCount = EventData;
	}

	/* All of the data has been received */
	if (Event == XUARTPS_EVENT_RECV_DATA) {
		xil_printf("Data Received: ");
		XUartPs_Recv(&UartPs, RecvBuffer, TEST_BUFFER_SIZE);
		xil_printf("%s\n\r",RecvBuffer);
		TotalReceivedCount = EventData;
		RX_FLAG = 1;
	}

	/*
	 * Data was received, but not the expected number of bytes, a
	 * timeout just indicates the data stopped for 8 character times
	 */
	if (Event == XUARTPS_EVENT_RECV_TOUT) {
		xil_printf("A receive timeout occurred\n\r");
		TotalReceivedCount = EventData;
	}

	/*
	 * Data was received with an error, keep the data but determine
	 * what kind of errors occurred
	 */
	if (Event == XUARTPS_EVENT_RECV_ERROR) {
		xil_printf("A receive error detected\n\r");
		TotalReceivedCount = EventData;
		TotalErrorCount++;
	}

}


/*****************************************************************************/
/**
*
* This function sets up the interrupt system so interrupts can occur for the
* Uart. This function is application-specific. The user should modify this
* function to fit the application.
*
* @param	IntcInstancePtr is a pointer to the instance of the INTC.
* @param	UartInstancePtr contains a pointer to the instance of the UART
*		driver which is going to be connected to the interrupt
*		controller.
* @param	UartIntrId is the interrupt Id and is typically
*		XPAR_<UARTPS_instance>_INTR value from xparameters.h.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None.
*
****************************************************************************/
static int SetupInterruptSystem(XScuGic *IntcInstancePtr,
				XUartPs *UartInstancePtr,
				u16 UartIntrId)
{
	int Status;

	XScuGic_Config *IntcConfig; /* Config for interrupt controller */

	/* Initialize the interrupt controller driver */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the interrupt controller interrupt handler to the
	 * hardware interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				(Xil_ExceptionHandler) XScuGic_InterruptHandler,
				IntcInstancePtr);

	/*
	 * Connect a device driver handler that will be called when an
	 * interrupt for the device occurs, the device driver handler
	 * performs the specific interrupt processing for the device
	 */
	Status = XScuGic_Connect(IntcInstancePtr, UartIntrId,
				  (Xil_ExceptionHandler) XUartPs_InterruptHandler,
				  (void *) UartInstancePtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Enable the interrupt for the device */
	XScuGic_Enable(IntcInstancePtr, UartIntrId);


	/* Enable interrupts */
	 Xil_ExceptionEnable();


	return XST_SUCCESS;
}
