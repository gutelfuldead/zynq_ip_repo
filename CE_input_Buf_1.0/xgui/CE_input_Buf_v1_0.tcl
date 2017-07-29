# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  set TAIL_SIZE [ipgui::add_param $IPINST -name "TAIL_SIZE"]
  set_property tooltip {Number of Tail Bytes to insert into the Convolutional Encoder} ${TAIL_SIZE}
  set BLOCK_SIZE [ipgui::add_param $IPINST -name "BLOCK_SIZE"]
  set_property tooltip {Number of Bytes in a block - Tail Bytes are stuffed after this number of bytes enter the core} ${BLOCK_SIZE}

}

proc update_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to update BLOCK_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to validate BLOCK_SIZE
	return true
}

proc update_PARAM_VALUE.TAIL_SIZE { PARAM_VALUE.TAIL_SIZE } {
	# Procedure called to update TAIL_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TAIL_SIZE { PARAM_VALUE.TAIL_SIZE } {
	# Procedure called to validate TAIL_SIZE
	return true
}

proc update_PARAM_VALUE.WORD_SIZE_IN { PARAM_VALUE.WORD_SIZE_IN } {
	# Procedure called to update WORD_SIZE_IN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WORD_SIZE_IN { PARAM_VALUE.WORD_SIZE_IN } {
	# Procedure called to validate WORD_SIZE_IN
	return true
}

proc update_PARAM_VALUE.WORD_SIZE_OUT { PARAM_VALUE.WORD_SIZE_OUT } {
	# Procedure called to update WORD_SIZE_OUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WORD_SIZE_OUT { PARAM_VALUE.WORD_SIZE_OUT } {
	# Procedure called to validate WORD_SIZE_OUT
	return true
}


proc update_MODELPARAM_VALUE.WORD_SIZE_OUT { MODELPARAM_VALUE.WORD_SIZE_OUT PARAM_VALUE.WORD_SIZE_OUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WORD_SIZE_OUT}] ${MODELPARAM_VALUE.WORD_SIZE_OUT}
}

proc update_MODELPARAM_VALUE.WORD_SIZE_IN { MODELPARAM_VALUE.WORD_SIZE_IN PARAM_VALUE.WORD_SIZE_IN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WORD_SIZE_IN}] ${MODELPARAM_VALUE.WORD_SIZE_IN}
}

proc update_MODELPARAM_VALUE.TAIL_SIZE { MODELPARAM_VALUE.TAIL_SIZE PARAM_VALUE.TAIL_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TAIL_SIZE}] ${MODELPARAM_VALUE.TAIL_SIZE}
}

proc update_MODELPARAM_VALUE.BLOCK_SIZE { MODELPARAM_VALUE.BLOCK_SIZE PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BLOCK_SIZE}] ${MODELPARAM_VALUE.BLOCK_SIZE}
}

