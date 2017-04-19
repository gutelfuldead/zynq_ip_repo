Digilent PMOD RS485 UART IP Core for ZedBoard configuration
===========================================================

(Digilent PmodRS485 Reference Manual)[https://reference.digilentinc.com/_media/pmod:pmod:pmodrs485_rm.pdf]

Vivado Setup
------------
1. enable **UART_0** on **Zynq7 Processing System** block
	1. double click system block to change properties
	1. peripheral i/o pins -> click **UART 0**
	1. PS-PL Configuration -> set **UART0 Baud Rate** to *115200*

1. Add block to repository
	1. Project Settings
	1. IP -> Repository Manager
	1. Add -> point to the top level IP core -> refresh all -> apply -> ok

1. Add pmod_rs485_controller IP to block
	1. Run Connection Automation (default options)
	1. Make the following Connections on the block diagram:
	
	| pmod_rs485_controller port | connection port                      |
	|----------------------------|--------------------------------------|
	| PS_RX                      | UART0_RX on zynq block               |
	| PS_TX                      | UART0_TX on zynq block               |
	| PMOD_RXD                   | create port : pmod_rs485_RXD type IN |
	| PMOD_TXD                   | create port : pmod_rs485_TXD type OUT|
	| DE                         | create port : pmod_rs485_DE  type OUT|
	| RE                         | create port : pmod_rs485_RE  type OUT|
	
	**NOTE** if using Vivado 2015.4 xparameters.h will not import the proper axi interface address from user created IP. Make sure to note the *offset address* being used by the core in the *address editor* tab of vivado

1. Use the JA1 top row Pmod ports to attach the Digilent PMOD RS485 UART device

1. Import the provided *zedboard_pmod_rs485.xdc* constraints file to map the pins

1. Generate Bit Stream and export Bit Stream and HDL to XSDK

XSDK Verification
-----------------

1. Create new empty project application and generate BSP
