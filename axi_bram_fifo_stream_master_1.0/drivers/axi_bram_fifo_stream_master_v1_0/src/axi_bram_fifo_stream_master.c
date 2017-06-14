

/***************************** Include Files *******************************/
#include "axi_bram_fifo_stream_master.h"

/************************** Function Definitions ***************************/

u32 ABFSM_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_BRAM_FIFO_STREAM_MASTER_mReadReg(baseaddr, ABFSM_CONTROL_REG_OFFSET);
}

void ABFSM_en_write_en(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg | ABFSM_WRITE_EN);
}

void ABFSM_den_write_en(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg & ~ABFSM_WRITE_EN);
}

void ABFSM_en_clken(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg | ABFSM_CLKEN);
}

void ABFSM_den_clken(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg & ~ABFSM_CLKEN);
}

void ABFSM_en_reset(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg | ABFSM_RESET);
}

void ABFSM_den_reset(const u32 baseaddr)
{
	const u32 reg = ABFSM_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr,ABFSM_CONTROL_REG_OFFSET, reg & ~ABFSM_RESET);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 ABFSM_poll_occupancy(const u32 baseaddr)
{
	return (AXI_BRAM_FIFO_STREAM_MASTER_mReadReg(baseaddr, ABFSM_OCCUPANCY_REG_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 ABFSM_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_STREAM_MASTER_mReadReg(baseaddr, ABFSM_STATUS_REG_OFFSET) & ABFSM_BRAM_FULL);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 ABFSM_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_STREAM_MASTER_mReadReg(baseaddr, ABFSM_STATUS_REG_OFFSET) & ABFSM_BRAM_EMPTY);
}

/**
 * @brief      write to the FILO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  datin     The input dat
 * @return     EABFSM_FILO_FULL if FILO is full, otherwise XST_SUCCESS
 */
u32 ABFSM_write_data(const u32 baseaddr, const u32 datin)
{
	if(ABFSM_poll_bram_full(baseaddr))
		return EABFSM_FIFO_FULL;
	AXI_BRAM_FIFO_STREAM_MASTER_mWriteReg(baseaddr, ABFSM_DIN_REG_OFFSET, datin);
	ABFSM_en_write_en(baseaddr);
	ABFSM_den_write_en(baseaddr);
	return XST_SUCCESS;
}

void ABFSM_disable_core(const u32 baseaddr)
{
    ABFSM_den_clken(baseaddr);
}

void ABFSM_init_core(const u32 baseaddr)
{
    ABFSM_en_reset(baseaddr);
    ABFSM_den_reset(baseaddr);
    ABFSM_en_clken(baseaddr);
}
