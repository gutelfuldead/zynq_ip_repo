/*
 * Make sure to set the proper address range in xparameters.h for the
 * STDIN_BASEADDRESSES and STDOUT_BASEADDRESSES
 * They should reflect the XPAR_PS7_UART_1_BASEADDR value
 */

#include "xparameters.h"
#include "xuartps.h"
#include "pmod_rs485_controller.h"

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define UART_DEVICE_ID                  XPAR_XUARTPS_0_DEVICE_ID

/* problem in vivado 2015.4 does not map user ip in xparameters.h */
/* must verify base address for PMOD_RS485 in vivado address editor tab */
#define PMOD_RS485_BASE_ADDR			0x43C00000

int pmod_rs485_ps_uart_example(u16 DeviceId);

XUartPs Uart_Ps;		/* The instance of the UART Driver */

int main(void)
{
	int Status;
	/* enable pmod_rs485_controller ip core */
	pmod_rs485_controller_enable(PMOD_RS485_BASE_ADDR);
	pmod_rs485_controller_enable_wr(PMOD_RS485_BASE_ADDR);
	pmod_rs485_controller_enable_rd(PMOD_RS485_BASE_ADDR);

	/* run example UART read/write */
	Status = pmod_rs485_ps_uart_example(UART_DEVICE_ID);

	return Status;
}

/**
 * sends and receives data from pmod device
 */
int pmod_rs485_ps_uart_example(u16 DeviceId)
{
	u8 send_buf[]="hello world";
	u8 len = sizeof(send_buf);
	u8 recv_buf[len];
	int SentCount = 0;
	int RecvCount = 0;
	int Status;
	XUartPs_Config *Config;

	/*
	 * Initialize the UART driver so that it's ready to use
	 * Look up the configuration in the config table and then initialize it.
	 */
	Config = XUartPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}

	Status = XUartPs_CfgInitialize(&Uart_Ps, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XUartPs_SetBaudRate(&Uart_Ps, 115200);
	int i;
	for(;;){
		for(i = 0; i < len; i++){
			SentCount += XUartPs_Send(&Uart_Ps,
						   &send_buf[i], 1);
			RecvCount += XUartPs_Recv(&Uart_Ps,
						   &recv_buf[i],1);
		}
		/* view results */
		xil_printf("UART1: SentCount = %d B, RecvCount = %d B, Received on UART0 = %s\n\r",
				(int)SentCount,(int)RecvCount,recv_buf);
		/* reset values */
		SentCount = 0;
		RecvCount = 0;
		memset(recv_buf,0,len);
	}
	return SentCount;
}
