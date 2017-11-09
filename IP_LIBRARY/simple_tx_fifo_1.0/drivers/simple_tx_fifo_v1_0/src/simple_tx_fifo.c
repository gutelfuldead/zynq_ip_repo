
/***************************** Include Files *******************************/
#include "simple_tx_fifo.h"

/************************** Function Definitions ***************************/

u32 STXFIFO_get_ctrl_reg(const u32 baseaddr)
{
	return SIMPLE_TX_FIFO_mReadReg(baseaddr, SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET);
}

void STXFIFO_en_write_en(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg | STXFIFO_WRITE_EN_MASK);
}

void STXFIFO_den_write_en(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg & ~STXFIFO_WRITE_EN_MASK);
}

void STXFIFO_en_clken(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg | STXFIFO_CLK_EN_MASK);
}

void STXFIFO_den_clken(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg & ~STXFIFO_CLK_EN_MASK);
}

void STXFIFO_en_reset(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg | STXFIFO_RESET_MASK);
}

void STXFIFO_den_reset(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg & ~STXFIFO_RESET_MASK);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 STXFIFO_poll_occupancy(const u32 baseaddr)
{
	return (SIMPLE_TX_FIFO_mReadReg(baseaddr, SIMPLE_TX_FIFO_OCCUPANCY_REG2_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 STXFIFO_poll_bram_full(const u32 baseaddr)
{
	return !!(SIMPLE_TX_FIFO_mReadReg(baseaddr, SIMPLE_TX_FIFO_STATUS_REG3_OFFSET) & STXFIFO_BRAM_FULL_MASK);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 STXFIFO_poll_bram_empty(const u32 baseaddr)
{
	return !!(SIMPLE_TX_FIFO_mReadReg(baseaddr, SIMPLE_TX_FIFO_STATUS_REG3_OFFSET) & STXFIFO_BRAM_EMPTY_MASK);
}

u8 STXFIFO_poll_bram_ready(const u32 baseaddr)
{
	return !!(SIMPLE_TX_FIFO_mReadReg(baseaddr, SIMPLE_TX_FIFO_STATUS_REG3_OFFSET) & STXFIFO_BRAM_READY_MASK);
}

/**
 * @brief      write to the FILO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  datin     The input dat
 * @return     ESTXFIFO_FILO_FULL if FILO is full, otherwise XST_SUCCESS
 */
u32 STXFIFO_write_data(const u32 baseaddr, const u32 datin)
{
	if(STXFIFO_poll_bram_full(baseaddr))
		return ESTXFIFO_FULL;
	XTime start = STXFIFO_get_time();
	while(STXFIFO_poll_bram_ready(baseaddr) == 0){
		if(STXFIFO_elapsed_time_us(start) > STXFIFO_POLL_VALID_MAX){
			return ESTXFIFO_NOT_RDY;
		}
	}
	SIMPLE_TX_FIFO_mWriteReg(baseaddr, SIMPLE_TX_FIFO_DATA_IN_REG1_OFFSET, datin);
	STXFIFO_en_write_en(baseaddr);
	STXFIFO_den_write_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * Sets write commit -- allows the master interface to begin transfers
 * @param baseaddr the base address of the core
 */
void STXFIFO_write_commit(const u32 baseaddr)
{
	const u32 reg = STXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg | STXFIFO_WR_COMMIT_MASK);
	SIMPLE_TX_FIFO_mWriteReg(baseaddr,SIMPLE_TX_FIFO_CONTROL_REG0_OFFSET, reg & ~STXFIFO_WR_COMMIT_MASK);
}	


void STXFIFO_disable_core(const u32 baseaddr)
{
    STXFIFO_den_clken(baseaddr);
}

void STXFIFO_init_core(const u32 baseaddr)
{
    STXFIFO_en_reset(baseaddr);
    STXFIFO_den_reset(baseaddr);
    STXFIFO_en_clken(baseaddr);
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime STXFIFO_get_time(void)
{
  XTime tmpTime;
  XTime_GetTime(&tmpTime);
  return tmpTime;
}

XTime STXFIFO_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = STXFIFO_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}
