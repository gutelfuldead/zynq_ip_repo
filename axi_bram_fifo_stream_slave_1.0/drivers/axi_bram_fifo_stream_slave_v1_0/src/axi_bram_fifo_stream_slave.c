

/***************************** Include Files *******************************/
#include "axi_bram_fifo_stream_slave.h"

/************************** Function Definitions ***************************/

u32 ABFSS_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_CONTROL_REG_OFFSET);
}

void ABFSS_en_clken(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg | ABFSS_CLKEN);
}

void ABFSS_den_clken(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg & ~ABFSS_CLKEN);
}

void ABFSS_en_read_en(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg | ABFSS_READ_EN);
}

void ABFSS_den_read_en(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg & ~ABFSS_READ_EN);
}

void ABFSS_en_reset(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg | ABFSS_RESET);
}

void ABFSS_den_reset(const u32 baseaddr)
{
	const u32 reg = ABFSS_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(baseaddr,ABFSS_CONTROL_REG_OFFSET, reg & ~ABFSS_RESET);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 ABFSS_poll_dout_valid(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_STATUS_REG_OFFSET) & ABFSS_DVALID);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 ABFSS_poll_occupancy(const u32 baseaddr)
{
	return (AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_OCCUPANCY_REG_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 ABFSS_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_STATUS_REG_OFFSET) & ABFSS_BRAM_FULL);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 ABFSS_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_STATUS_REG_OFFSET) & ABFSS_BRAM_EMPTY);
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the ABFSS_DOUT_VALID signal
 *             doesn't go high after a time specified by ABFSS_POLL_VALID_MAX define in header.
 *             Failure will also occur as a result of the FILO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     EABFSS_FILO_EMPTY, EABFSS_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 ABFSS_read_data(const u32 baseaddr, u32 *datout)
{
	if(ABFSS_poll_bram_empty(baseaddr))
		return EABFSS_FIFO_EMPTY;
	ABFSS_en_read_en(baseaddr);
	XTime start = ABFSS_get_time();
	while(ABFSS_poll_dout_valid(baseaddr) == 0){
		if(ABFSS_elapsed_time_us(start) > ABFSS_POLL_VALID_MAX){
			ABFSS_den_read_en(baseaddr);		
			return EABFSS_VALID_NOT_ASSERTED;
		}
	}
	*datout = AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(baseaddr, ABFSS_DATA_OUT_REG_OFFSET);
	ABFSS_den_read_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      returns elapsed time from input time in microseconds
 * @param[in]  Start reference XTime
 * @return     elapsed time in us
 */
XTime ABFSS_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = ABFSS_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void ABFSS_disable_core(const u32 baseaddr)
{
    ABFSS_den_clken(baseaddr);
}

void ABFSS_init_core(const u32 baseaddr)
{
    ABFSS_en_reset(baseaddr);
    ABFSS_den_reset(baseaddr);
    ABFSS_en_clken(baseaddr);
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime ABFSS_get_time(void)
{
  XTime tmpTime;
  XTime_GetTime(&tmpTime);
  return tmpTime;
}
