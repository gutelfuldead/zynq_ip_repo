# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "INPUT_CLK_MHZ"
  ipgui::add_param $IPINST -name "SPI_CLK_MHZ"

}

proc update_PARAM_VALUE.DSIZE { PARAM_VALUE.DSIZE } {
	# Procedure called to update DSIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DSIZE { PARAM_VALUE.DSIZE } {
	# Procedure called to validate DSIZE
	return true
}

proc update_PARAM_VALUE.INPUT_CLK_MHZ { PARAM_VALUE.INPUT_CLK_MHZ } {
	# Procedure called to update INPUT_CLK_MHZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_CLK_MHZ { PARAM_VALUE.INPUT_CLK_MHZ } {
	# Procedure called to validate INPUT_CLK_MHZ
	return true
}

proc update_PARAM_VALUE.SPI_CLK_MHZ { PARAM_VALUE.SPI_CLK_MHZ } {
	# Procedure called to update SPI_CLK_MHZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SPI_CLK_MHZ { PARAM_VALUE.SPI_CLK_MHZ } {
	# Procedure called to validate SPI_CLK_MHZ
	return true
}


proc update_MODELPARAM_VALUE.INPUT_CLK_MHZ { MODELPARAM_VALUE.INPUT_CLK_MHZ PARAM_VALUE.INPUT_CLK_MHZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_CLK_MHZ}] ${MODELPARAM_VALUE.INPUT_CLK_MHZ}
}

proc update_MODELPARAM_VALUE.SPI_CLK_MHZ { MODELPARAM_VALUE.SPI_CLK_MHZ PARAM_VALUE.SPI_CLK_MHZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SPI_CLK_MHZ}] ${MODELPARAM_VALUE.SPI_CLK_MHZ}
}

proc update_MODELPARAM_VALUE.DSIZE { MODELPARAM_VALUE.DSIZE PARAM_VALUE.DSIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DSIZE}] ${MODELPARAM_VALUE.DSIZE}
}

