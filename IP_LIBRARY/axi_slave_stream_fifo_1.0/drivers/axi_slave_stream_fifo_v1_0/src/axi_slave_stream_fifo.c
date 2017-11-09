

/***************************** Include Files *******************************/
#include "axi_slave_stream_fifo.h"

/************************** Function Definitions ***************************/

u32 ASSF_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_CONTROL_REG_OFFSET);
}

void ASSF_en_clken(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg | ASSF_CLKEN);
}

void ASSF_den_clken(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg & ~ASSF_CLKEN);
}

void ASSF_en_read_en(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg | ASSF_READ_EN);
}

void ASSF_den_read_en(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg & ~ASSF_READ_EN);
}

void ASSF_en_reset(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg | ASSF_RESET);
}

void ASSF_den_reset(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg & ~ASSF_RESET);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 ASSF_poll_dout_valid(const u32 baseaddr)
{
	return !!(AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_STATUS_REG_OFFSET) & ASSF_DVALID);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 ASSF_poll_occupancy(const u32 baseaddr)
{
	return (AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_OCCUPANCY_REG_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 ASSF_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_STATUS_REG_OFFSET) & ASSF_BRAM_FULL);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 ASSF_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_STATUS_REG_OFFSET) & ASSF_BRAM_EMPTY);
}

/**
 * @brief Tells hardware the read was successful
 * @param baseaddr The baseaddr
 */
void ASSF_read_done(const u32 baseaddr)
{
	const u32 reg = ASSF_get_ctrl_reg(baseaddr);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg | ASSF_READ_DN);
	AXI_SLAVE_STREAM_FIFO_mWriteReg(baseaddr,ASSF_CONTROL_REG_OFFSET, reg & ~ASSF_READ_DN);
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the ASSF_DOUT_VALID signal
 *             doesn't go high after a time specified by ASSF_POLL_VALID_MAX define in header.
 *             Failure will also occur as a result of the FILO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     EASSF_FILO_EMPTY, EASSF_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 ASSF_read_data(const u32 baseaddr, u32 *datout)
{
	if(ASSF_poll_bram_empty(baseaddr))
		return EASSF_FIFO_EMPTY;
	ASSF_en_read_en(baseaddr);
	ASSF_den_read_en(baseaddr);		
	XTime start = ASSF_get_time();
	while(ASSF_poll_dout_valid(baseaddr) == 0){
		if(ASSF_elapsed_time_us(start) > ASSF_POLL_VALID_MAX){
			return EASSF_VALID_NOT_ASSERTED;
		}
	}
	*datout = AXI_SLAVE_STREAM_FIFO_mReadReg(baseaddr, ASSF_DATA_OUT_REG_OFFSET);
	return XST_SUCCESS;
}

/**
 * @brief      returns elapsed time from input time in microseconds
 * @param[in]  Start reference XTime
 * @return     elapsed time in us
 */
XTime ASSF_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = ASSF_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void ASSF_disable_core(const u32 baseaddr)
{
    ASSF_den_clken(baseaddr);
}

void ASSF_init_core(const u32 baseaddr)
{
    ASSF_en_reset(baseaddr);
    ASSF_den_reset(baseaddr);
    ASSF_en_clken(baseaddr);
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime ASSF_get_time(void)
{
  XTime tmpTime;
  XTime_GetTime(&tmpTime);
  return tmpTime;
}
