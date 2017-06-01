axi_bram_fifo_controller_1.0
============================

If the BRAM address width is changed the driver needs to be updated to reflect this. The header file currently has the hex hardcoded for the drive width l.16 and l.35 of `axi_bram_fifo_controller.h`:

```

	l.16 : #define BRAM_ADDR_WIDTH 10
	l.35 : AFIFO_OCCUPANCY  = 0x3ff, // 10 bits

```

These two fields must be updated. Maximum width is 32b - (3 overhead bits) = 29b. If a FIFO of size 2^29 is needed there are bigger fish to fry.
