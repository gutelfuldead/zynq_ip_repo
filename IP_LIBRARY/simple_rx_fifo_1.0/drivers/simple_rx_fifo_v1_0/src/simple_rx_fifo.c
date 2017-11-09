

/***************************** Include Files *******************************/
#include "simple_rx_fifo.h"

/************************** Function Definitions ***************************/

u32 SRXFIFO_get_ctrl_reg(const u32 baseaddr)
{
	return SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET);
}

void SRXFIFO_en_clken(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg | SRXFIFO_CLK_EN_BIT_MASK);
}

void SRXFIFO_den_clken(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg & ~SRXFIFO_CLK_EN_BIT_MASK);
}

void SRXFIFO_en_read_en(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg | SRXFIFO_READ_EN_BIT_MASK);
}

void SRXFIFO_den_read_en(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg & ~SRXFIFO_READ_EN_BIT_MASK);
}

void SRXFIFO_en_reset(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg | SRXFIFO_RESET_BIT_MASK);
}

void SRXFIFO_den_reset(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg & ~SRXFIFO_RESET_BIT_MASK);
}

/**
 * @brief      polls the dout valid
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for valid, 0 otherwise
 */
u8 SRXFIFO_poll_dout_valid(const u32 baseaddr)
{
	return !!(SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_STATUS_REG1_OFFSET) & SRXFIFO_DATA_VALID_BIT_MASK);
}

/**
 * returns occupancy count of the fifo
 * @param  baseaddr the baseaddr
 * @return          number of data locations within the fifo
 */
u32 SRXFIFO_poll_occupancy(const u32 baseaddr)
{
	return (SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_OCCUPANCY_REG2_OFFSET));
}


/**
 * @brief      polls the bram full value
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for full, 0 otherwise
 */
u8 SRXFIFO_poll_bram_full(const u32 baseaddr)
{
	return !!(SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_STATUS_REG1_OFFSET) & SRXFIFO_BRAM_FULL_BIT_MASK);
}

/**
 * @brief      polls the bram empty value 
 * @param[in]  baseaddr  The baseaddr
 * @return     1 for empty, 0 otherwise
 */
u8 SRXFIFO_poll_bram_empty(const u32 baseaddr)
{
	return !!(SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_STATUS_REG1_OFFSET) & SRXFIFO_BRAM_EMPTY_BIT_MASK);
}

/**
 * @brief Tells hardware the read was successful
 * @param baseaddr The baseaddr
 */
void SRXFIFO_read_done(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg | SRXFIFO_READ_DONE_BIT_MASK);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg & ~SRXFIFO_READ_DONE_BIT_MASK);
}

/**
 * @brief      read from fifo; uses a timer to send a failure return if the SRXFIFO_DOUT_VALID signal
 *             doesn't go high after a time specified by SRXFIFO_POLL_VALID_MAX define in header.
 *             Failure will also occur as a result of the FILO being empty
 * @param[in]  baseaddr  The baseaddr
 * @param      datout    The datout
 * @return     ESRXFIFO_FILO_EMPTY, ESRXFIFO_VALID_NOT_ASSERTED, or XST_SUCCESS
 */
u32 SRXFIFO_read_data(const u32 baseaddr, u32 *datout)
{
	if(SRXFIFO_poll_bram_empty(baseaddr))
		return ESRXFIFO_EMPTY;
	SRXFIFO_en_read_en(baseaddr);
	SRXFIFO_den_read_en(baseaddr);		
	XTime start = SRXFIFO_get_time();
	while(SRXFIFO_poll_dout_valid(baseaddr) == 0){
		if(SRXFIFO_elapsed_time_us(start) > SRXFIFO_POLL_VALID_MAX){
			return ESRXFIFO_VALID_NOT_ASSERTED;
		}
	}
	*datout = SIMPLE_RX_FIFO_mReadReg(baseaddr, SIMPLE_RX_FIFO_DATA_OUT_REG3_OFFSET);
	SRXFIFO_read_done(baseaddr);
	return XST_SUCCESS;
}

/**
 * @brief      returns elapsed time from input time in microseconds
 * @param[in]  Start reference XTime
 * @return     elapsed time in us
 */
XTime SRXFIFO_elapsed_time_us(const XTime startTime)
{
  XTime tempXTime;
  tempXTime = SRXFIFO_get_time();
  tempXTime = tempXTime - startTime;
  tempXTime = tempXTime / ((COUNTS_PER_SECOND) / 1000000UL); 
  return (tempXTime);
}

void SRXFIFO_irq_en(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg | SRXFIFO_IRQ_EN_BIT_MASK);
}

void SRXFIFO_irq_den(const u32 baseaddr)
{
	const u32 reg = SRXFIFO_get_ctrl_reg(baseaddr);
	SIMPLE_RX_FIFO_mWriteReg(baseaddr,SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET, reg & ~SRXFIFO_IRQ_EN_BIT_MASK);
}


void SRXFIFO_disable_core(const u32 baseaddr)
{
	SRXFIFO_irq_den(baseaddr);
    SRXFIFO_den_clken(baseaddr);
}

void SRXFIFO_init_core(const u32 baseaddr)
{
    SRXFIFO_en_reset(baseaddr);
    SRXFIFO_den_reset(baseaddr);
    SRXFIFO_en_clken(baseaddr);
    SRXFIFO_irq_den(baseaddr);
}

/**
 * @brief      Used to capture the processor time using the XTime Xilinx type
 * @return     The time in us.
 */
XTime SRXFIFO_get_time(void)
{
  XTime tmpTime;
  XTime_GetTime(&tmpTime);
  return tmpTime;
}

void SRXFIFO_write_interrupt_level(const u32 baseaddr, const u32 interrupt_level)
{
	SIMPLE_RX_FIFO_mWriteReg(baseaddr, SIMPLE_RX_FIFO_IRQ_LEVEL_REG4_OFFSET, interrupt_level);
	SRXFIFO_irq_en(baseaddr);
}

void SRXFIFO_EnableInterrupt(void * baseaddr_p)
{
 u32 baseaddr;
 baseaddr = (u32) baseaddr_p;
 /*
 * Enable all interrupt source from user logic.
 */
 SIMPLE_RX_FIFO_mWriteReg(baseaddr, 0x4, 0x1);
 /*
 * Set global interrupt enable.
 */
 SIMPLE_RX_FIFO_mWriteReg(baseaddr, 0x0, 0x1);
}

void SRXFIFO_ACK(void * baseaddr_p)
{
 u32 baseaddr;
 baseaddr = (u32) baseaddr_p;

 /*
 * ACK interrupts on NS_TDMA_SLOT_GEN.
 */
 SIMPLE_RX_FIFO_mWriteReg(baseaddr, 0xc, 0x1);
}

int XSRXFIFO_CfgInitialize(Xsrxfifo * InstancePtr, Xsrxfifo_config * Config,
			UINTPTR EffectiveAddr)
{
	/* Assert arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/* Set some default values. */
	InstancePtr->BaseAddress = EffectiveAddr;

	InstancePtr->InterruptPresent = Config->InterruptPresent;

	/*
	 * Indicate the instance is now ready to use, initialized without error
	 */
	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;
	return (XST_SUCCESS);
}