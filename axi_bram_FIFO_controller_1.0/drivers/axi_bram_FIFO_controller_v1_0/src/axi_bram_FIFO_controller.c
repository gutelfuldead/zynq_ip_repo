

/***************************** Include Files *******************************/
#include "AXI_BRAM_FIFO_CONTROLLER.h"
#include "xil_types.h"
/************************** Function Definitions ***************************/

u32 ABFC_get_ctrl_reg(const u32 baseaddr)
{
	return ABFC_mReadReg(baseaddr, ABFC_CTRL_REG);
}

void ABFC_en_ABFC_WRITE_EN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_WRITE_EN);
}

void ABFC_den_ABFC_WRITE_EN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_WRITE_EN);
}

void ABFC_en_ABFC_CLKEN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_CLKEN);
}

void ABFC_den_ABFC_CLKEN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_CLKEN);
}

void ABFC_en_ABFC_READ_EN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_READ_EN);
}

void ABFC_den_ABFC_READ_EN(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_READ_EN);
}

void ABFC_en_ABFC_RESET(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg | ABFC_RESET);
}

void ABFC_den_ABFC_RESET(const u32 baseaddr)
{
	const u32 reg = ABFC_get_ctrl_reg(baseaddr);
	ABFC_mWriteReg(baseaddr,ABFC_CTRL_REG, reg & ~ABFC_RESET);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 ABFC_poll_ABFC_DOUT_VALID(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_DOUT_VALID);
}

/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 ABFC_poll_ABFC_BRAM_FULL(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_BRAM_FULL);	
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 ABFC_poll_ABFC_BRAM_EMPTY(const u32 baseaddr)
{
	return !!(ABFC_mReadReg(baseaddr, ABFC_STATUS_REG) & ABFC_BRAM_EMPTY);	
}

/**
 * @brief      write to the FIFO
 * @param[in]  baseaddr  The baseaddr
 * @param[in]  dat       The dat
 * @return     EABFC_FIFO_FULL if FIFO is full, otherwise XST_SUCCESS
 */
u32 ABFC_write_data(const u32 baseaddr, const u32 dat)
{
	if(ABFC_poll_ABFC_BRAM_FULL(baseaddr))
		return EABFC_FIFO_FULL;
	ABFC_mWriteReg(baseaddr, ABFC_DIN_REG, dat);
	ABFC_en_ABFC_WRITE_EN(baseaddr);
	ABFC_den_ABFC_WRITE_EN(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      used for first read from fifo after writes have occured. Used to tell the IP to decrement
 * 			   the fifo pointer to the appropriate location
 * @param[in]  baseaddr  The baseaddr
 */
void ABFC_read_prep(const u32 baseaddr)
{
	ABFC_en_ABFC_READ_EN(baseaddr);
	ABFC_den_ABFC_READ_EN(baseaddr);
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the ABFC_DOUT_VALID signal
 *             doesn't go high after a time specified by MAX_WAIT_POLL_VALID_US define in header.
 *             Failure will also occur as a result of the FIFO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     EABFC_FIFO_EMPTY, EABFC_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 ABFC_read_data(const u32 baseaddr, u32 *datout)
{
	if(ABFC_poll_ABFC_BRAM_EMPTY(baseaddr))
		return EABFC_FIFO_EMPTY;
	ABFC_en_ABFC_READ_EN(baseaddr);
	XTime start = ABFC_get_time();
	while(ABFC_poll_ABFC_DOUT_VALID(baseaddr) == 0){
		if(ABFC_elapsed_time_us(start) > MAX_WAIT_POLL_VALID_US){
			ABFC_den_ABFC_READ_EN(baseaddr);		
			return EABFC_VALID_NOT_ASSERTED;
		}
	}
	*datout = ABFC_mReadReg(baseaddr, ABFC_DOUT_REG);
	ABFC_den_ABFC_READ_EN(baseaddr);
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
  tempXTime = get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void ABFC_print_error(const int err)
{
    switch(err){
        case EABFC_FIFO_FULL :
            printf("Error Writing FIFO full\n\r");
            break;
        case EABFC_FIFO_EMPTY :
            printf("Error reading FIFO empty\n\r");
            break;
        case EABFC_VALID_NOT_ASSERTED :
            printf("Valid not asserted within %d us\n\r",MAX_US_WAIT);
            break;
    }       
}

void ABFC_disable_core(const u32 baseaddr)
{
    ABFC_den_ABFC_CLKEN(baseaddr);
}

void ABFC_init_core(const u32 baseaddr)
{
    ABFC_en_ABFC_RESET(baseaddr);
    ABFC_den_ABFC_RESET(baseaddr);
    ABFC_en_ABFC_CLKEN(baseaddr);
}