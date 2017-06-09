axi_bram_fifo_controller_1.0
============================

Usage
-----

In order to perform a write call the `AFIFO_write_data` function. If the FIFO is full an error will be returned.

In order to perform a read first check the occupancy of the core with the `AFIFO_poll_occupancy` function. Then read up to that amount with the `AFIFO_read_data` function. If a read is performed and the core is empty an error will be returned.

If the core does not assert a data valid signal within `AFIFO_MAX_US_WAIT` microseconds defined in `axi_bram_fifo_controller.h` then an error will be returned.

The `AFIFO_init_core` will perform a soft reset of the core then set the enable signal.

The `AFIFO_disable_core` will disable the enable signal.


Block Memory Generator parameters
---------------------------------

|   tab    |    Option     |    Setting    |
|----------|---------------|---------------|
| Basic    | Mode          | Stand Alone   |
| Basic    | Memory Type   | Simple Dual Port RAM |
| Basic    | Common Clock  | Check         |
| Port A Options | Enable Port Type | Use ENA Pin |