AXI_BRAM_FILO_CONTROLLER_1.0
============================

This core implements a simple AXI4-Lite driven FILO wrapper to raw BRAM ports. Generics on the core must match the FILO address and data widths while not exceeding the maximum data width of the AXI4-Lite interface.

Test code `bram_fifo_test.c` provided showing read/write operations to the core.

Due to the way the FILO address pointer is implemented a single clock cycle is required between the last read operation and the first read operation to correct the index. 