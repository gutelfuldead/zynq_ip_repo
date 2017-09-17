# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  set reference_clk [ipgui::add_param $IPINST -name "reference_clk"]
  set_property tooltip {Hz} ${reference_clk}

}

proc update_PARAM_VALUE.reference_clk { PARAM_VALUE.reference_clk } {
	# Procedure called to update reference_clk when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.reference_clk { PARAM_VALUE.reference_clk } {
	# Procedure called to validate reference_clk
	return true
}


proc update_MODELPARAM_VALUE.reference_clk { MODELPARAM_VALUE.reference_clk PARAM_VALUE.reference_clk } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.reference_clk}] ${MODELPARAM_VALUE.reference_clk}
}

