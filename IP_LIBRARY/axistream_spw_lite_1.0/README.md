axistream_spw_lite_1.0
----------------------

# Functionality

The core instantiates a spacewire interface with an AXI-Stream wrapper.

## Slave

The TLAST flag is used to generate an spw EOP byte

## Master

The TLAST flag is generated on the last byte before the EOP byte is sent

# SpaceWire Lite IP
Core uses SpaceWire Lite vhdl files acquired from opencores - https://opencores.org/project/spacewire_light

The SpaceWire Lite VHDL has been un-modified. The source code is located in the ./src directory along with the licenses and original readme


