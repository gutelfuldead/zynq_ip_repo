/**
 * This example will send data on the UART0 device and then wait for rx flag to be asserted by
 * the interrupt controller. The data will then be printed out and a new packet will be sent.
 * Forever, and ever, and ever.
 *
 * Make sure to set the proper address range in xparameters.h for the
 * STDIN_BASEADDRESSES and STDOUT_BASEADDRESSES
 * They should reflect the XPAR_PS7_UART_1_BASEADDR value
 *
 * Expected output (prints via usb/uart with UART1 controller):
 * ```
 * Data Sent
 * 		Data Received: "ABCDEFGHIJ"
 * ```
 */

#include "xparameters.h"
#include "xplatform_info.h"
#include "xuartps.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xil_printf.h"

#define UART_DEVICE_ID		XPAR_XUARTPS_0_DEVICE_ID
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define UART_INT_IRQ_ID		XPAR_XUARTPS_0_INTR
#define TEST_BUFFER_SIZE	10

#define STDIN_BASEADDRESS XPAR_PS7_UART_1_BASEADDR
#define STDOUT_BASEADDRESS XPAR_PS7_UART_1_BASEADDR

int UART_SETUP(XScuGic *IntcInstPtr, XUartPs *UartInstPtr,
			u16 DeviceId, u16 UartIntrId);
static int SetupInterruptSystem(XScuGic *IntcInstancePtr,
				XUartPs *UartInstancePtr,
				u16 UartIntrId);
void Handler(void *CallBackRef, u32 Event, unsigned int EventData);

XUartPs UartPs	;		/* Instance of the UART Device */
XScuGic InterruptController;	/* Instance of the Interrupt Controller */

static u8 RecvBuffer[2];	/* Buffer for Receiving Data */

volatile int TotalReceivedCount;
volatile int TotalSentCount;
volatile int RX_FLAG = 1;

int TotalErrorCount;

int main(void)
{
	int Status;

	xil_printf("\n\r------------------------------------\n\r");
	xil_printf("PMOD RS485 Interrupt Controller Test\n\r");
	xil_printf("------------------------------------\n\r");

	/* Run the UartPs Interrupt example, specify the the Device ID */
	Status = UART_SETUP(&InterruptController, &UartPs,
				UART_DEVICE_ID, UART_INT_IRQ_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("UART Setup Example Test Failed\r\n");
		return XST_FAILURE;
	}

	char *inp = "\n\rinput : ";
	RecvBuffer[1] = '\0';
	for(;;){
		if(RX_FLAG == 1){
			XUartPs_Send(&UartPs, inp, strlen(inp));
			RX_FLAG = 0;
		}
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
int UART_SETUP(XScuGic *IntcInstPtr, XUartPs *UartInstPtr,
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

//	UartInstPtr->BaudRate = 115200;
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
	XUartPs_SetRecvTimeout(UartInstPtr, 8);

	/*
	 * Send the buffer using the UART and ignore the number of bytes sent
	 * as the return value since we are using it in interrupt mode.
	 */

	return XST_SUCCESS;
}

void Handler(void *CallBackRef, u32 Event, unsigned int EventData)
{

	/* All of the data has been sent */
	if (Event == XUARTPS_EVENT_SENT_DATA) {
//		xil_printf("\tData Sent from serial line\n\r");
		TotalSentCount = EventData;
	}

	/* All of the data has been received */
	if (Event == XUARTPS_EVENT_RECV_DATA) {
		TotalReceivedCount = EventData;
		XUartPs_Recv(&UartPs, &RecvBuffer[0], TotalReceivedCount);
		xil_printf("\tData Received from serial: \"%c\"\n\r",RecvBuffer[0]);
		XUartPs_Send(&UartPs, RecvBuffer, sizeof(RecvBuffer));
		RX_FLAG = 1;
	}

	/*
	 * Data was received, but not the expected number of bytes, a
	 * timeout just indicates the data stopped for 8 character times
	 */
	if (Event == XUARTPS_EVENT_RECV_TOUT) {
		xil_printf("\tA receive timeout occurred\n\r");
		TotalReceivedCount = EventData;
//		XUartPs_Recv(&UartPs, &RecvBuffer, TotalReceivedCount);
		xil_printf("\t\"%s\"\n",RecvBuffer);
	}

	/*
	 * Data was received with an error, keep the data but determine
	 * what kind of errors occurred
	 */
	if (Event == XUARTPS_EVENT_RECV_ERROR) {
		xil_printf("\tA receive error detected\n\r");
		TotalReceivedCount = EventData;
		TotalErrorCount++;
		xil_printf("\terrcnt = %d\n\r",TotalErrorCount);
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
