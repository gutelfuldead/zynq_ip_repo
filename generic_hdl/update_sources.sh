#!/bin/bash
# Synchronizes the .vhd files located in the generic_hdl folder current for all IP Cores that use them

# source generic files to copy
SRC0=axi_master_stream.vhd
SRC1=axi_slave_stream.vhd
SRC2=generic_pkg.vhd
SRC3=pulse_generator.vhd
SRC4=bram_fifo_controller.vhd
SRC5=spi_master.vhd
SRC6=spi_slave.vhd

# readable names of axi ip cores for messages
NM0=axi_master_stream_fifo_1.0
NM1=axi_slave_stream_fifo_1.0
NM2=byte_to_word_streamer_1.0
NM3=word_to_byte_streamer_1.0
NM4=byte_to_bit_streamer_1.0
NM5=convolution_to_viterbi_converter_stream_1.0
NM6=bits_to_byte_streamer_1.0
NM7=reset_controller_1.0
NM8=sid_input_buffer_1.0
NM9=sid_output_buffer_1.0
NM10=viterbi_input_buffer_1.0
NM11=viterbi_output_buffer_1.0
NM12=CE_input_Buf_1.0
NM13=CE_output_buf_1.0
NM14=axis_to_spi_1.0
NM15=spi_to_axis_1.0
NM16=axis_data_buf_1.0

# destination of cores to copy into
DST0=../$NM0/src
DST1=../$NM1/src
DST2=../$NM2/src
DST3=../$NM3/src
DST4=../$NM4/src
DST5=../$NM5/src
DST6=../$NM6/src
DST7=../$NM7/src
DST8=../$NM8/src
DST9=../$NM9/src
DST10=../$NM10/src
DST11=../$NM11/src
DST12=../$NM12/src
DST13=../$NM13/src
DST14=../$NM14/src
DST15=../$NM15/src
DST16=../$NM16/src

# update all IP source folders
echo "Updating $NM0 with $SRC0 and $SRC2"
cp $SRC0 $SRC2 $DST0

echo "Updating $NM1 with $SRC1 and $SRC2"
cp $SRC1 $SRC2 $DST1

echo "Updating $NM2 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST2

echo "Updating $NM3 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST3

echo "Updating $NM4 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST4

echo "Updating $NM5 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST5

echo "Updating $NM6 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST6

echo "Updating $NM7 with $SRC2 and $SRC3"
cp $SRC2 $SRC3 $DST7

echo "Updating $NM8 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST8

echo "Updating $NM9 with $SRC0 and $SRC2"
cp $SRC0 $SRC2 $DST9

echo "Updating $NM10 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST10

echo "Updating $NM11 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST11

echo "Updating $NM12 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST12

echo "Updating $NM13 with $SRC0, $SRC1, $SRC2"
cp $SRC0 $SRC1 $SRC2 $DST13

echo "Updating $NM14 with $SRC1, $SRC2, $SRC5"
cp $SRC1 $SRC2 $SRC5 $DST14

echo "Updating $NM15 with $SRC0, $SRC2, $SRC6"
cp $SRC0 $SRC2 $SRC6 $DST15

echo "Updating $NM16 with $SRC0, $SRC1, $SRC2, $SRC4"
cp $SRC0 $SRC1 $SRC2 $SRC4 $DST16