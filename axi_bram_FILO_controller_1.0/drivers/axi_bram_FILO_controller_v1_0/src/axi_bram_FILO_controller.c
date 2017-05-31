

/***************************** Include Files *******************************/
#include "axi_bram_FILO_controller.h"
/************************** Function Definitions ***************************/

u32 ABFC_get_ctrl_reg(const u32 baseaddr)
{
	return ABFC_mReadReg(baseaddr, ABFC_CTRL_REG);
}

void ABFC_en_write_en(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_WRITE_EN);
}

void ABFC_den_write_en(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_WRITE_EN);
}

void ABFC_en_clken(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_CLKEN);
}

void ABFC_den_clken(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_CLKEN);
}

void ABFC_en_read_en(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_READ_EN);
}

void ABFC_den_read_en(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_READ_EN);
}

void ABFC_en_reset(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_RESET);
}

void ABFC_den_reset(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_RESET);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 ABFC_poll_dout_valid(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_DOUT_VALID);
}

/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 ABFC_poll_bram_full(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_BRAM_FULL);	
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 ABFC_poll_bram_empty(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_BRAM_EMPTY);	
}

/**
 * @brief      write to the FILO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  datin     The input dat
 * @return     EABFC_FILO_FULL if FILO is full, otherwise XST_SUCCESS
 */
u32 ABFC_write_data(const u32 baseaddr, const u32 datin)
{
	if(ABFC_poll_bram_full(baseaddr))
		return EABFC_FILO_FULL;
	ABFC_mWriteReg(baseaddr, ABFC_DIN_REG, datin);
	ABFC_en_write_en(baseaddr);
	ABFC_den_write_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      used for first read from fifo after writes have occured. Used to tell the IP to decrement
 * 			   the fifo pointer to the appropriate location
 * @param[in]  baseaddr  The baseaddr
 */
void ABFC_read_prep(const u32 baseaddr)
{
	ABFC_en_read_en(baseaddr);
	ABFC_den_read_en(baseaddr);
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the ABFC_DOUT_VALID signal
 *             doesn't go high after a time specified by ABFC_POLL_VALID_MAX define in header.
 *             Failure will also occur as a result of the FILO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     EABFC_FILO_EMPTY, EABFC_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 ABFC_read_data(const u32 baseaddr, u32 *datout)
{
	if(ABFC_poll_bram_empty(baseaddr))
		return EABFC_FILO_EMPTY;
	ABFC_en_read_en(baseaddr);
	XTime start = ABFC_get_time();
	while(ABFC_poll_dout_valid(baseaddr) == 0){
		if(ABFC_elapsed_time_us(start) > ABFC_POLL_VALID_MAX){
			ABFC_den_read_en(baseaddr);		
			return EABFC_VALID_NOT_ASSERTED;
		}
	}
	*datout = ABFC_mReadReg(baseaddr, ABFC_DOUT_REG);
	ABFC_den_read_en(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime ABFC_get_time(void)
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
XTime ABFC_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = ABFC_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void ABFC_print_error(const int err)
{
    switch(err){
        case EABFC_FILO_FULL :
            printf("Error Writing FILO full\n\r");
            break;
        case EABFC_FILO_EMPTY :
            printf("Error reading FILO empty\n\r");
            break;
        case EABFC_VALID_NOT_ASSERTED :
            printf("Valid not asserted within %d us\n\r",ABFC_MAX_US_WAIT);
            break;
    }       
}

void ABFC_disable_core(const u32 baseaddr)
{
    ABFC_den_clken(baseaddr);
}

void ABFC_init_core(const u32 baseaddr)
{
    ABFC_en_reset(baseaddr);
    ABFC_den_reset(baseaddr);
    ABFC_en_clken(baseaddr);
}