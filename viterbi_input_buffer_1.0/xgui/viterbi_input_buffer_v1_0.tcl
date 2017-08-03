# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  set PRIME_SIZE [ipgui::add_param $IPINST -name "PRIME_SIZE"]
  set_property tooltip {Number of Bytes used to Prime the Viterbi Core} ${PRIME_SIZE}
  set BLOCK_SIZE [ipgui::add_param $IPINST -name "BLOCK_SIZE"]
  set_property tooltip {Size of bytes in a transmission block} ${BLOCK_SIZE}

}

proc update_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to update BLOCK_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BLOCK_SIZE { PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to validate BLOCK_SIZE
	return true
}

proc update_PARAM_VALUE.PRIME_SIZE { PARAM_VALUE.PRIME_SIZE } {
	# Procedure called to update PRIME_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PRIME_SIZE { PARAM_VALUE.PRIME_SIZE } {
	# Procedure called to validate PRIME_SIZE
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

proc update_MODELPARAM_VALUE.PRIME_SIZE { MODELPARAM_VALUE.PRIME_SIZE PARAM_VALUE.PRIME_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PRIME_SIZE}] ${MODELPARAM_VALUE.PRIME_SIZE}
}

proc update_MODELPARAM_VALUE.BLOCK_SIZE { MODELPARAM_VALUE.BLOCK_SIZE PARAM_VALUE.BLOCK_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BLOCK_SIZE}] ${MODELPARAM_VALUE.BLOCK_SIZE}
}

