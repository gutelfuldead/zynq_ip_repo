zynq_ip_repo
============

This repository contains multiple IP Cores designed for the Zynq7000 series SoC. Some include Xilinx primitives and AXI interfaces. All IP contain `./tb` subfolder with test bench files. Any IP with an AXI4-Lite interface to the processor contains sufficient software drivers and doxy comments for usage.

axi_bram_fifo_controller_1.0
----------------------------
AXI4-Lite read and write interface to dual port BRAM. When configuring BRAM must choose common clock. This device uses the BUFG to set the BRAM clock ports (clka,clkb). Functional but depricated. Does not use newest bram fifo controller found in `./generic_hdl`. 

axi_master_stream_fifo_1.0
--------------------------
AXI4-Lite write interface to Dual Port BRAM FIFO when data is in the FIFO the core will automatically begin transfers over the AXI-Stream Master Interface. Includes device driver.

axi_slave_stream_fifo_1.0
-------------------------
Accepts data from an independent AXI4-Stream Slave interface and writes it to the FIFO. Allows independent reads from the FIFO over AXI4-Lite interface. Includes device driver.

button_interrupt_1.0
--------------------
Generates an interrupt to the processor whenever a button is pressed. Doesn't currently inform which button was pressed. **todo: fix to inform which button was pressed**

byte_to_word_streamer_1.0
-------------------------
Takes in 8-bits at a time over AXI-Stream Slave interface and will wait for more until either 16 or 32 bits are available (based on generics) and outputs the 16/32b word on the AXI-Stream Master interface.

clock_gen_irq_1.0
-----------------
Generates an interrupt on a clock divider.

generic_hdl
-----------
Contains the AXI-Stream Master and Slave Interface vhds, The BRAM controller vhd, a pulse generator vhd, and a generic_pkg.vhd file which contains component declarations. Also contains a bash script to update all of the other cores who share these files so a change can be propagated quickly.

gps_pps_generator_1.0
---------------------
Simulates a GPS PPS signal which is active low triggered every 1 second with a 100MHz input clock. Contains drivers to enable and disable from PS over AXI4-Lite.

led_controller_1.0
------------------
Interface to control the LEDs from BareMetal application code over AXI4-Lite; contains drivers. 

pmod_rs485_controller_1.0
-------------------------
No actual vhd but contains instructions on how to control a specific PMOD RS485 device as a UART interface.

tdma_slot_generator_1.0
-----------------------
Takes a GPS PPS signal and generates a new pulse every x ms based on generics. If a second passes without an input GPS PPS pulse then the core will cease to function until a new pulse is encountered. Interrupts processor with every pulse with information about whether it was a core generated pulse or the GPS PPS signal itself. Optional output pin that is an active high version of the irq pulse. Contains drivers to configure the device from AXI4-Lite.

word_to_byte_streamer_1.0
-------------------------
Counterpart to byte_to_word_streamer_1.0 which takes a 16 or 32 bit word over the AXI-Stream Slave interface and sends out a series of 8-bit outputs to the AXI-Stream Master interface. Pipelined to be always ready to output data.

byte_to_bit_streamer_1.0
------------------------
Takes in a byte over AXI-Stream Slave Interface and then sends one byte at a time with the LSB being progressively taken from the input byte in little endian order and sent along the AXI-Stream Master Interface. Developed to be used with [Xilinx Interleaver Core](https://www.xilinx.com/support/documentation/ip_documentation/sid/v8_0/pg049-sid.pdf) to the [Xilinx Convolutional Encoder](https://www.xilinx.com/support/documentation/ip_documentation/convolution/v9_0/pg026_convolution.pdf) Core.

convolution_to_viterbi_converter_stream_1.0
-------------------------------------------
Used as a glue core to connect the [Xilinx Convolutional Encoder](https://www.xilinx.com/support/documentation/ip_documentation/convolution/v9_0/pg026_convolution.pdf) and [Xilinx Viterbi Decoder](https://www.xilinx.com/support/documentation/ip_documentation/viterbi/v9_1/pg027_viterbi_decoder.pdf) cores for testing purposes.

bits_to_byte_streamer_1.0
----------------------------
Takes a series of bits over an 8bit bus axi4-stream slave interface buffers them internally until a full byte is received then sends it out over the axi4-stream master interface.
