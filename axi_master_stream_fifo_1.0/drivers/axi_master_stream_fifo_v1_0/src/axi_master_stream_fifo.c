

/***************************** Include Files *******************************/
#include "axi_master_stream_fifo.h"

/************************** Function Definitions ***************************/

u32 AMSF_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_MASTER_STREAM_FIFO_mReadReg(baseaddr, AMSF_CONTROL_REG_OFFSET);
}

void AMSF_en_write_en(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg | AMSF_WRITE_EN);
}

void AMSF_den_write_en(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg & ~AMSF_WRITE_EN);
}

void AMSF_en_clken(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg | AMSF_CLKEN);
}

void AMSF_den_clken(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg & ~AMSF_CLKEN);
}

void AMSF_en_reset(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg | AMSF_RESET);
}

void AMSF_den_reset(const u32 baseaddr)
{
	const u32 reg = AMSF_get_ctrl_reg(baseaddr);
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr,AMSF_CONTROL_REG_OFFSET, reg & ~AMSF_RESET);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 AMSF_poll_occupancy(const u32 baseaddr)
{
	return (AXI_MASTER_STREAM_FIFO_mReadReg(baseaddr, AMSF_OCCUPANCY_REG_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 AMSF_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_MASTER_STREAM_FIFO_mReadReg(baseaddr, AMSF_STATUS_REG_OFFSET) & AMSF_BRAM_FULL);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 AMSF_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_MASTER_STREAM_FIFO_mReadReg(baseaddr, AMSF_STATUS_REG_OFFSET) & AMSF_BRAM_EMPTY);
}

/**
 * @brief      write to the FILO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  datin     The input dat
 * @return     EAMSF_FILO_FULL if FILO is full, otherwise XST_SUCCESS
 */
u32 AMSF_write_data(const u32 baseaddr, const u32 datin)
{
	if(AMSF_poll_bram_full(baseaddr))
		return EAMSF_FIFO_FULL;
	AXI_MASTER_STREAM_FIFO_mWriteReg(baseaddr, AMSF_DIN_REG_OFFSET, datin);
	AMSF_en_write_en(baseaddr);
	AMSF_den_write_en(baseaddr);
	return XST_SUCCESS;
}

void AMSF_disable_core(const u32 baseaddr)
{
    AMSF_den_clken(baseaddr);
}

void AMSF_init_core(const u32 baseaddr)
{
    AMSF_en_reset(baseaddr);
    AMSF_den_reset(baseaddr);
    AMSF_en_clken(baseaddr);
}
