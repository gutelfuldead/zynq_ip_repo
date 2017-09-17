# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_INTR_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_INTR_HIGHADDR" -parent ${Page_0}

  set input_freq [ipgui::add_param $IPINST -name "input_freq"]
  set_property tooltip {hz} ${input_freq}
  set output_freq [ipgui::add_param $IPINST -name "output_freq"]
  set_property tooltip {Hz} ${output_freq}

}

proc update_PARAM_VALUE.input_freq { PARAM_VALUE.input_freq } {
	# Procedure called to update input_freq when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.input_freq { PARAM_VALUE.input_freq } {
	# Procedure called to validate input_freq
	return true
}

proc update_PARAM_VALUE.output_freq { PARAM_VALUE.output_freq } {
	# Procedure called to update output_freq when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.output_freq { PARAM_VALUE.output_freq } {
	# Procedure called to validate output_freq
	return true
}

proc update_PARAM_VALUE.ps_enable { PARAM_VALUE.ps_enable } {
	# Procedure called to update ps_enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ps_enable { PARAM_VALUE.ps_enable } {
	# Procedure called to validate ps_enable
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_BASEADDR { PARAM_VALUE.C_S_AXI_INTR_BASEADDR } {
	# Procedure called to update C_S_AXI_INTR_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_BASEADDR { PARAM_VALUE.C_S_AXI_INTR_BASEADDR } {
	# Procedure called to validate C_S_AXI_INTR_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_HIGHADDR { PARAM_VALUE.C_S_AXI_INTR_HIGHADDR } {
	# Procedure called to update C_S_AXI_INTR_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_HIGHADDR { PARAM_VALUE.C_S_AXI_INTR_HIGHADDR } {
	# Procedure called to validate C_S_AXI_INTR_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.input_freq { MODELPARAM_VALUE.input_freq PARAM_VALUE.input_freq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.input_freq}] ${MODELPARAM_VALUE.input_freq}
}

proc update_MODELPARAM_VALUE.output_freq { MODELPARAM_VALUE.output_freq PARAM_VALUE.output_freq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.output_freq}] ${MODELPARAM_VALUE.output_freq}
}

proc update_MODELPARAM_VALUE.ps_enable { MODELPARAM_VALUE.ps_enable PARAM_VALUE.ps_enable } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ps_enable}] ${MODELPARAM_VALUE.ps_enable}
}

