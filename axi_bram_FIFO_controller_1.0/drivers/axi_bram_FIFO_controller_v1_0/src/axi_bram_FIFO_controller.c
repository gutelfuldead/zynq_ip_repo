

/***************************** Include Files *******************************/
#include "axi_bram_FIFO_controller.h"
#include "xil_types.h"
/************************** Function Definitions ***************************/

u32 AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_REG);
}

void AXI_BRAM_FIFO_CONTROLLER_en_write_en(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg | WRITE_EN);
}

void AXI_BRAM_FIFO_CONTROLLER_den_write_en(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg & ~WRITE_EN);
}

void AXI_BRAM_FIFO_CONTROLLER_en_clken(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg | CLKEN);
}

void AXI_BRAM_FIFO_CONTROLLER_den_clken(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg & ~CLKEN);
}

void AXI_BRAM_FIFO_CONTROLLER_en_read_en(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg | READ_EN);
}

void AXI_BRAM_FIFO_CONTROLLER_den_read_en(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg & ~READ_EN);
}

void AXI_BRAM_FIFO_CONTROLLER_en_reset(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg | RESET);
}

void AXI_BRAM_FIFO_CONTROLLER_den_reset(const u32 baseaddr)
{
	const u32 reg = AXI_BRAM_FIFO_CONTROLLER_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AXI_BRAM_FIFO_CONTROLLER_REG, reg & ~RESET);
}

u8 AXI_BRAM_FIFO_CONTROLLER_poll_dout_valid(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_OUTPUT_CONTROL_REG) & DOUT_VALID);
}

u8 AXI_BRAM_FIFO_CONTROLLER_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_OUTPUT_CONTROL_REG) & BRAM_FULL);	
}

u8 AXI_BRAM_FIFO_CONTROLLER_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_OUTPUT_CONTROL_REG) & BRAM_EMPTY);	
}

u32 AXI_BRAM_FIFO_CONTROLLER_write_data(const u32 baseaddr, const u32 dat)
{
	if(AXI_BRAM_FIFO_CONTROLLER_poll_bram_full(baseaddr))
		return XST_FAILURE;
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_DIN_REG, dat);
	AXI_BRAM_FIFO_CONTROLLER_en_write_en(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_den_write_en(baseaddr);
	return XST_SUCCESS;
}

void AXI_BRAM_FIFO_CONTROLLER_read_prep(const u32 baseaddr)
{
	AXI_BRAM_FIFO_CONTROLLER_en_read_en(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_den_read_en(baseaddr);
}

u32 AXI_BRAM_FIFO_CONTROLLER_read_data(const u32 baseaddr, u32 *datout)
{
	if(AXI_BRAM_FIFO_CONTROLLER_poll_bram_empty(baseaddr))
		return XST_FAILURE;
	AXI_BRAM_FIFO_CONTROLLER_en_read_en(baseaddr);
	while(AXI_BRAM_FIFO_CONTROLLER_poll_dout_valid(baseaddr) == 0){}
	*datout = AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AXI_BRAM_FIFO_CONTROLLER_DOUT_REG);
	AXI_BRAM_FIFO_CONTROLLER_den_read_en(baseaddr);
	return XST_SUCCESS;
}