

/***************************** Include Files *******************************/
#include "fifo_axi_buffer.h"

/************************** Function Definitions ***************************/

/**
  * performs soft reset on fifo_axi_buffer
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  */
void fifo_reset(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
    /* SOFT RESET */
    FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, RESET);
    FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, 0X0);
    return;
}

/**
  * sets RD_EN in the status register
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  */
void fifo_set_read(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	u32 tmp = fifo_get_status_register(FIFO_AXI_BUFFER_BASE_ADDR);
	FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, tmp | RD_EN);
	return;
}

/**
  * disables RD_EN in the status register
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  */
void fifo_disable_read(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	u32 tmp = fifo_get_status_register(FIFO_AXI_BUFFER_BASE_ADDR);
	FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, tmp & ~RD_EN);
	return;
}

/**
  * sets WR_EN in the status register
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  */
void fifo_set_write(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	u32 tmp = fifo_get_status_register(FIFO_AXI_BUFFER_BASE_ADDR);
	FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, tmp | WR_EN);
	return;
}

/**
  * disables WR_EN in the status register
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  */
void fifo_disable_write(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	u32 tmp = fifo_get_status_register(FIFO_AXI_BUFFER_BASE_ADDR);
	FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET, tmp & ~WR_EN);
	return;
}

/**
  * reads data from the FIFO
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  * @return the u32 FIFO data
  */
u32 fifo_get_data(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	return FIFO_AXI_BUFFER_mReadReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_DOUT_REG_OFFSET);
}

/**
  * writes data to the FIFO
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  * @param din is the data to write to the FIFO
  */
void fifo_write_data(u32 FIFO_AXI_BUFFER_BASE_ADDR,u32 din)
{
	FIFO_AXI_BUFFER_mWriteReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_DIN_REG_OFFSET, din);
	return;
}

/**
  * returns the status register
  * @param FIFO_AXI_BUFFER_BASE_ADDER base address for IP
  * @return the u32 status register
  */
u32 fifo_get_status_register(u32 FIFO_AXI_BUFFER_BASE_ADDR)
{
	return FIFO_AXI_BUFFER_mReadReg(FIFO_AXI_BUFFER_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_CONTROL_REG_OFFSET);
}