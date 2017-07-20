#!/bin/bash
# Synchronizes the .vhd files located in the generic_hdl folder current for all IP Cores that use them

# source generic files to copy
SRC0=axi_master_stream.vhd
SRC1=axi_slave_stream.vhd
SRC2=generic_pkg.vhd
SRC3=pulse_generator.vhd

# readable names of axi ip cores for messages
NM0=axi_master_stream_fifo_1.0
NM1=axi_slave_stream_fifo_1.0
NM2=byte_to_word_streamer_1.0
NM3=word_to_byte_streamer_1.0
NM4=byte_to_bit_streamer_1.0
NM5=convolution_to_viterbi_converter_stream_1.0
NM6=bits_to_byte_streamer_1.0

# destination of cores to copy into
DST0=../$NM0/src
DST1=../$NM1/src
DST2=../$NM2/src
DST3=../$NM3/src
DST4=../$NM4/src
DST5=../$NM5/src
DST6=../$NM6/src

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
