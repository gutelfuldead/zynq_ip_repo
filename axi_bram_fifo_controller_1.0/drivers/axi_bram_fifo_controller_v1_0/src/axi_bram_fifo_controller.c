

/***************************** Include Files *******************************/
#include "axi_bram_fifo_controller.h"

/************************** Function Definitions ***************************/

u32 AFIFO_get_ctrl_reg(const u32 baseaddr)
{
	return AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_CTRL_REG);
}

void AFIFO_en_write_en(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg | AFIFO_WRITE_EN);
}

void AFIFO_den_write_en(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg & ~AFIFO_WRITE_EN);
}

void AFIFO_en_clken(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg | AFIFO_CLKEN);
}

void AFIFO_den_clken(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg & ~AFIFO_CLKEN);
}

void AFIFO_en_read_en(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg | AFIFO_READ_EN);
}

void AFIFO_den_read_en(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg & ~AFIFO_READ_EN);
}

void AFIFO_en_reset(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg | AFIFO_RESET);
}

void AFIFO_den_reset(const u32 baseaddr)
{
	const u32 reg = AFIFO_get_ctrl_reg(baseaddr);
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr,AFIFO_CTRL_REG, reg & ~AFIFO_RESET);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 AFIFO_poll_dout_valid(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_STATUS_REG) & AFIFO_DVALID);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 AFIFO_poll_occupancy(const u32 baseaddr)
{
	return (AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_STATUS_REG) & AFIFO_OCCUPANCY);
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 AFIFO_poll_bram_full(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_STATUS_REG) & AFIFO_BRAM_FULL);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 AFIFO_poll_bram_empty(const u32 baseaddr)
{
	return !!(AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_STATUS_REG) & AFIFO_BRAM_EMPTY);
}

/**
 * @brief      write to the FILO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  datin     The input dat
 * @return     EAFIFO_FILO_FULL if FILO is full, otherwise XST_SUCCESS
 */
u32 AFIFO_write_data(const u32 baseaddr, const u32 datin)
{
	if(AFIFO_poll_bram_full(baseaddr))
		return EAFIFO_FIFO_FULL;
	AXI_BRAM_FIFO_CONTROLLER_mWriteReg(baseaddr, AFIFO_DIN_REG, datin);
	AFIFO_en_write_en(baseaddr);
	AFIFO_den_write_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the AFIFO_DOUT_VALID signal
 *             doesn't go high after a time specified by AFIFO_POLL_VALID_MAX define in header.
 *             Failure will also occur as a result of the FILO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     EAFIFO_FILO_EMPTY, EAFIFO_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 AFIFO_read_data(const u32 baseaddr, u32 *datout)
{
	if(AFIFO_poll_bram_empty(baseaddr))
		return EAFIFO_FIFO_EMPTY;
	AFIFO_en_read_en(baseaddr);
	XTime start = AFIFO_get_time();
	while(AFIFO_poll_dout_valid(baseaddr) == 0){
		if(AFIFO_elapsed_time_us(start) > AFIFO_POLL_VALID_MAX){
			AFIFO_den_read_en(baseaddr);		
			return EAFIFO_VALID_NOT_ASSERTED;
		}
	}
	*datout = AXI_BRAM_FIFO_CONTROLLER_mReadReg(baseaddr, AFIFO_DOUT_REG);
	AFIFO_den_read_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * Used to switch the BRAM data line from write to read (decrement by one)
 * @param baseaddr the base address
 */
void AFIFO_read_prep(const u32 baseaddr)
{
	AFIFO_en_read_en(baseaddr);
	AFIFO_den_read_en(baseaddr);		
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime AFIFO_get_time(void)
{
  XTime tmpTime;
  XTime_GetTime(&tmpTime);
  return tmpTime;
}

/**
 * @brief      returns elapsed time from input time in microseconds
 * @param[in]  Start reference XTime
 * @return     elapsed time in us
 */
XTime AFIFO_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = AFIFO_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void AFIFO_print_error(const int err)
{
    switch(err){
        case EAFIFO_FIFO_FULL :
            printf("Error Writing FIFO full\n\r");
            break;
        case EAFIFO_FIFO_EMPTY :
            printf("Error reading FIFO empty\n\r");
            break;
        case EAFIFO_VALID_NOT_ASSERTED :
            printf("Valid not asserted within %d us\n\r",AFIFO_MAX_US_WAIT);
            break;
    }       
}

void AFIFO_disable_core(const u32 baseaddr)
{
    AFIFO_den_clken(baseaddr);
}

void AFIFO_init_core(const u32 baseaddr)
{
    AFIFO_en_reset(baseaddr);
    AFIFO_den_reset(baseaddr);
    AFIFO_en_clken(baseaddr);
}
