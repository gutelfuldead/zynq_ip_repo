# zedboard configuration for PMOD RS485 (only)
# configure the PMOD RS485 device to work on PMOD ports JA1 (top row)
set_property PACKAGE_PIN AA11 [get_ports pmod_rs485_TXD]
set_property PACKAGE_PIN Y10 [get_ports pmod_rs485_RXD]
set_property PACKAGE_PIN AA9 [get_ports pmod_rs485_DE]
set_property PACKAGE_PIN Y11 [get_ports pmod_rs485_RE]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_rs485_RXD]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_rs485_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_rs485_DE]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_rs485_RE]