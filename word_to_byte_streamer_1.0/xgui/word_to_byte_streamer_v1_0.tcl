# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "WORD_SIZE_IN" -widget comboBox

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

