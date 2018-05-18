
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/axistream_spw_lite_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  set sysfreq [ipgui::add_param $IPINST -name "sysfreq"]
  set_property tooltip {System clock frequency in Hz. This must be set to the frequency of "clk". It is used to setup counters for reset timing, disconnect timeout and to transmit at 10 Mbit/s during the link handshake.} ${sysfreq}
  set tximpl_fast [ipgui::add_param $IPINST -name "tximpl_fast"]
  set_property tooltip {When true generates the fast front-end transmitter. Uses individual txclk port.} ${tximpl_fast}
  set rximpl_fast [ipgui::add_param $IPINST -name "rximpl_fast"]
  set_property tooltip {When true generates the fast front-end receiver. Uses individual rxclk port.} ${rximpl_fast}
  set txclkfreq [ipgui::add_param $IPINST -name "txclkfreq"]
  set_property tooltip {Transmit clock frequency in Hz (only if tximpl = impl_fast). This must be set to the frequency of "txclk". It is used to transmit at 10 Mbit/s during the link handshake.} ${txclkfreq}
  set rxchunk_fast [ipgui::add_param $IPINST -name "rxchunk_fast"]
  set_property tooltip {Maximum number of bits received per system clock (must be 1 in case of impl_generic).} ${rxchunk_fast}
  set rxfifosize_bits [ipgui::add_param $IPINST -name "rxfifosize_bits"]
  set_property tooltip {Size of the receive FIFO as the 2-logarithm of the number of bytes. Must be at least 6 (64 bytes).} ${rxfifosize_bits}
  set txfifosize_bits [ipgui::add_param $IPINST -name "txfifosize_bits"]
  set_property tooltip {Size of the transmit FIFO as the 2-logarithm of the number of bytes.} ${txfifosize_bits}
  set txdivcnt [ipgui::add_param $IPINST -name "txdivcnt"]
  set_property tooltip {Scaling factor minus 1, used to scale the transmit base clock into the transmission bit rate. The system clock (for impl_generic) or the txclk (for impl_fast) is divided by (unsigned(txdivcnt) + 1). Changing this signal will immediately change the transmission rate. During link setup, the transmission rate is always 10 Mbit/s.} ${txdivcnt}

}

proc update_PARAM_VALUE.rxchunk_fast { PARAM_VALUE.rxchunk_fast PARAM_VALUE.rximpl_fast } {
	# Procedure called to update rxchunk_fast when any of the dependent parameters in the arguments change
	
	set rxchunk_fast ${PARAM_VALUE.rxchunk_fast}
	set rximpl_fast ${PARAM_VALUE.rximpl_fast}
	set values(rximpl_fast) [get_property value $rximpl_fast]
	if { [gen_USERPARAMETER_rxchunk_fast_ENABLEMENT $values(rximpl_fast)] } {
		set_property enabled true $rxchunk_fast
	} else {
		set_property enabled false $rxchunk_fast
	}
}

proc validate_PARAM_VALUE.rxchunk_fast { PARAM_VALUE.rxchunk_fast } {
	# Procedure called to validate rxchunk_fast
	return true
}

proc update_PARAM_VALUE.txclkfreq { PARAM_VALUE.txclkfreq PARAM_VALUE.tximpl_fast } {
	# Procedure called to update txclkfreq when any of the dependent parameters in the arguments change
	
	set txclkfreq ${PARAM_VALUE.txclkfreq}
	set tximpl_fast ${PARAM_VALUE.tximpl_fast}
	set values(tximpl_fast) [get_property value $tximpl_fast]
	if { [gen_USERPARAMETER_txclkfreq_ENABLEMENT $values(tximpl_fast)] } {
		set_property enabled true $txclkfreq
	} else {
		set_property enabled false $txclkfreq
	}
}

proc validate_PARAM_VALUE.txclkfreq { PARAM_VALUE.txclkfreq } {
	# Procedure called to validate txclkfreq
	return true
}

proc update_PARAM_VALUE.rxfifosize_bits { PARAM_VALUE.rxfifosize_bits } {
	# Procedure called to update rxfifosize_bits when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.rxfifosize_bits { PARAM_VALUE.rxfifosize_bits } {
	# Procedure called to validate rxfifosize_bits
	return true
}

proc update_PARAM_VALUE.rximpl_fast { PARAM_VALUE.rximpl_fast } {
	# Procedure called to update rximpl_fast when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.rximpl_fast { PARAM_VALUE.rximpl_fast } {
	# Procedure called to validate rximpl_fast
	return true
}

proc update_PARAM_VALUE.sysfreq { PARAM_VALUE.sysfreq } {
	# Procedure called to update sysfreq when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.sysfreq { PARAM_VALUE.sysfreq } {
	# Procedure called to validate sysfreq
	return true
}

proc update_PARAM_VALUE.txdivcnt { PARAM_VALUE.txdivcnt } {
	# Procedure called to update txdivcnt when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.txdivcnt { PARAM_VALUE.txdivcnt } {
	# Procedure called to validate txdivcnt
	return true
}

proc update_PARAM_VALUE.txfifosize_bits { PARAM_VALUE.txfifosize_bits } {
	# Procedure called to update txfifosize_bits when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.txfifosize_bits { PARAM_VALUE.txfifosize_bits } {
	# Procedure called to validate txfifosize_bits
	return true
}

proc update_PARAM_VALUE.tximpl_fast { PARAM_VALUE.tximpl_fast } {
	# Procedure called to update tximpl_fast when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.tximpl_fast { PARAM_VALUE.tximpl_fast } {
	# Procedure called to validate tximpl_fast
	return true
}


proc update_MODELPARAM_VALUE.sysfreq { MODELPARAM_VALUE.sysfreq PARAM_VALUE.sysfreq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.sysfreq}] ${MODELPARAM_VALUE.sysfreq}
}

proc update_MODELPARAM_VALUE.txclkfreq { MODELPARAM_VALUE.txclkfreq PARAM_VALUE.txclkfreq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.txclkfreq}] ${MODELPARAM_VALUE.txclkfreq}
}

proc update_MODELPARAM_VALUE.rxchunk_fast { MODELPARAM_VALUE.rxchunk_fast PARAM_VALUE.rxchunk_fast } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.rxchunk_fast}] ${MODELPARAM_VALUE.rxchunk_fast}
}

proc update_MODELPARAM_VALUE.rxfifosize_bits { MODELPARAM_VALUE.rxfifosize_bits PARAM_VALUE.rxfifosize_bits } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.rxfifosize_bits}] ${MODELPARAM_VALUE.rxfifosize_bits}
}

proc update_MODELPARAM_VALUE.txfifosize_bits { MODELPARAM_VALUE.txfifosize_bits PARAM_VALUE.txfifosize_bits } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.txfifosize_bits}] ${MODELPARAM_VALUE.txfifosize_bits}
}

proc update_MODELPARAM_VALUE.txdivcnt { MODELPARAM_VALUE.txdivcnt PARAM_VALUE.txdivcnt } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.txdivcnt}] ${MODELPARAM_VALUE.txdivcnt}
}

proc update_MODELPARAM_VALUE.rximpl_fast { MODELPARAM_VALUE.rximpl_fast PARAM_VALUE.rximpl_fast } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.rximpl_fast}] ${MODELPARAM_VALUE.rximpl_fast}
}

proc update_MODELPARAM_VALUE.tximpl_fast { MODELPARAM_VALUE.tximpl_fast PARAM_VALUE.tximpl_fast } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.tximpl_fast}] ${MODELPARAM_VALUE.tximpl_fast}
}

