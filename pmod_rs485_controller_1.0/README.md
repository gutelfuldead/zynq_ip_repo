Digilent PMOD RS485 UART IP Core for ZedBoard configuration
===========================================================

[Digilent PmodRS485 Reference Manual](https://reference.digilentinc.com/_media/pmod:pmod:pmodrs485_rm.pdf)

[485DRCI Industrial RS-232 to RS-422/485 Converter](http://www.bb-elec.com/Products/Datasheets/pn_7207R5_485DRCI-2212ds.pdf)

> also confirmed to work with this device as an interface to PC

Vivado Setup
------------
1. enable **UART_0** on **Zynq7 Processing System** block
	1. double click system block to change properties
	1. peripheral i/o pins -> click **UART 0**
	1. PS-PL Configuration -> set **UART0 Baud Rate** to *115200*

1. 
	
	| pmod_rs485_controller port | connection port                      |
	|----------------------------|--------------------------------------|
	| PS7/UART0_RX               | create port : pmod_rs485_RXD type IN |
	| PS7/UART0_TX               | create port : pmod_rs485_TXD type OUT|
	| Xilinx Constant Block = 1  | create port : pmod_rs485_DE  type OUT|
	| Xilinx Constant Block = 0  | create port : pmod_rs485_RE  type OUT|
	

1. Use the JA1 top row Pmod ports to attach the Digilent PMOD RS485 UART device

1. Import the provided *zedboard_pmod_rs485.xdc* constraints file to map the pins

1. Generate Bit Stream and export Bit Stream and HDL to XSDK

XSDK Verification
-----------------

1. Create new empty project application and generate BSP

1. In the BSP must hand alter the xparameters.h file to set the STDIN/STDOUT_BASEADDRESS to be that of the UART1 device if it is desirable to view debug messages via the USB UART connection. Essentially using UART1 via the UART/USB port and UART0 for the pmod device. Via `xparameters.h` :

```
#define STDIN_BASEADDRESS 0xE0001000  // XPAR_PS7_UART_1_BASEADDR
#define STDOUT_BASEADDRESS 0xE0001000 // XPAR_PS7_UART_1_BASEADDR
```
1. Example program `loopback_example.c` provided to flood UART0 with "hello world" and recieve it back in loopback mode. The USB UART1 will print results to a terminal session. 

1. Example program `irq_test.c` will prompt data to be input on a serial terminal then output the received data on the usb/uart terminal.

1. Example program `polling_test.c` will constantly poll the serial uart until a certain amount of data is received then print it to the usb/uart terminal.

