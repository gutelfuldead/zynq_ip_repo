
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/AXIS_MONITOR_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S00_AXI_DATA_WIDTH}
  set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Width of S_AXI address bus} ${C_S00_AXI_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}

  ipgui::add_param $IPINST -name "AXIS_DWIDTH"
  set S_TUSER_EN [ipgui::add_param $IPINST -name "S_TUSER_EN"]
  set_property tooltip {Enable TUSER line} ${S_TUSER_EN}
  ipgui::add_param $IPINST -name "AXIS_UWIDTH"
  ipgui::add_param $IPINST -name "S_TUSER_BIT_ON"
  set S_TUSER_BIT_LEVEL [ipgui::add_param $IPINST -name "S_TUSER_BIT_LEVEL"]
  set_property tooltip {Records when the monitored bit is at this level} ${S_TUSER_BIT_LEVEL}

}

proc update_PARAM_VALUE.AXIS_UWIDTH { PARAM_VALUE.AXIS_UWIDTH PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to update AXIS_UWIDTH when any of the dependent parameters in the arguments change
	
	set AXIS_UWIDTH ${PARAM_VALUE.AXIS_UWIDTH}
	set S_TUSER_EN ${PARAM_VALUE.S_TUSER_EN}
	set values(S_TUSER_EN) [get_property value $S_TUSER_EN]
	if { [gen_USERPARAMETER_AXIS_UWIDTH_ENABLEMENT $values(S_TUSER_EN)] } {
		set_property enabled true $AXIS_UWIDTH
	} else {
		set_property enabled false $AXIS_UWIDTH
	}
}

proc validate_PARAM_VALUE.AXIS_UWIDTH { PARAM_VALUE.AXIS_UWIDTH } {
	# Procedure called to validate AXIS_UWIDTH
	return true
}

proc update_PARAM_VALUE.S_TUSER_BIT_LEVEL { PARAM_VALUE.S_TUSER_BIT_LEVEL PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to update S_TUSER_BIT_LEVEL when any of the dependent parameters in the arguments change
	
	set S_TUSER_BIT_LEVEL ${PARAM_VALUE.S_TUSER_BIT_LEVEL}
	set S_TUSER_EN ${PARAM_VALUE.S_TUSER_EN}
	set values(S_TUSER_EN) [get_property value $S_TUSER_EN]
	if { [gen_USERPARAMETER_S_TUSER_BIT_LEVEL_ENABLEMENT $values(S_TUSER_EN)] } {
		set_property enabled true $S_TUSER_BIT_LEVEL
	} else {
		set_property enabled false $S_TUSER_BIT_LEVEL
	}
}

proc validate_PARAM_VALUE.S_TUSER_BIT_LEVEL { PARAM_VALUE.S_TUSER_BIT_LEVEL } {
	# Procedure called to validate S_TUSER_BIT_LEVEL
	return true
}

proc update_PARAM_VALUE.S_TUSER_BIT_ON { PARAM_VALUE.S_TUSER_BIT_ON PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to update S_TUSER_BIT_ON when any of the dependent parameters in the arguments change
	
	set S_TUSER_BIT_ON ${PARAM_VALUE.S_TUSER_BIT_ON}
	set S_TUSER_EN ${PARAM_VALUE.S_TUSER_EN}
	set values(S_TUSER_EN) [get_property value $S_TUSER_EN]
	if { [gen_USERPARAMETER_S_TUSER_BIT_ON_ENABLEMENT $values(S_TUSER_EN)] } {
		set_property enabled true $S_TUSER_BIT_ON
	} else {
		set_property enabled false $S_TUSER_BIT_ON
	}
}

proc validate_PARAM_VALUE.S_TUSER_BIT_ON { PARAM_VALUE.S_TUSER_BIT_ON } {
	# Procedure called to validate S_TUSER_BIT_ON
	return true
}

proc update_PARAM_VALUE.AXIS_DWIDTH { PARAM_VALUE.AXIS_DWIDTH } {
	# Procedure called to update AXIS_DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_DWIDTH { PARAM_VALUE.AXIS_DWIDTH } {
	# Procedure called to validate AXIS_DWIDTH
	return true
}

proc update_PARAM_VALUE.S_TUSER_EN { PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to update S_TUSER_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.S_TUSER_EN { PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to validate S_TUSER_EN
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
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


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.S_TUSER_EN { MODELPARAM_VALUE.S_TUSER_EN PARAM_VALUE.S_TUSER_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_TUSER_EN}] ${MODELPARAM_VALUE.S_TUSER_EN}
}

proc update_MODELPARAM_VALUE.S_TUSER_BIT_ON { MODELPARAM_VALUE.S_TUSER_BIT_ON PARAM_VALUE.S_TUSER_BIT_ON } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_TUSER_BIT_ON}] ${MODELPARAM_VALUE.S_TUSER_BIT_ON}
}

proc update_MODELPARAM_VALUE.S_TUSER_BIT_LEVEL { MODELPARAM_VALUE.S_TUSER_BIT_LEVEL PARAM_VALUE.S_TUSER_BIT_LEVEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.S_TUSER_BIT_LEVEL}] ${MODELPARAM_VALUE.S_TUSER_BIT_LEVEL}
}

proc update_MODELPARAM_VALUE.AXIS_DWIDTH { MODELPARAM_VALUE.AXIS_DWIDTH PARAM_VALUE.AXIS_DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_DWIDTH}] ${MODELPARAM_VALUE.AXIS_DWIDTH}
}

proc update_MODELPARAM_VALUE.AXIS_UWIDTH { MODELPARAM_VALUE.AXIS_UWIDTH PARAM_VALUE.AXIS_UWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_UWIDTH}] ${MODELPARAM_VALUE.AXIS_UWIDTH}
}

