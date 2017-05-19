
#ifndef AXI_BRAM_FIFO_CONTROLLER_H
#define AXI_BRAM_FIFO_CONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include <xtime_l.h>
#include "xstatus.h"

enum SLV_REGISTERS{
	ABFC_CTRL_REG                = 0,
	ABFC_DOUT_REG           = 4,
	ABFC_STATUS_REG         = 8,
	ABFC_DIN_REG            = 12
};

enum FIFO_CONTROL_REG_BITS{
	WRITE_EN = (1 << 0),
	READ_EN  = (1 << 1),
	RESET    = (1 << 2),
	CLKEN    = (1 << 3)
};

enum FIFO_OUTPUT_CONTROL_REG_BITS{
	DOUT_VALID = (1 << 0),
	BRAM_FULL  = (1 << 1),
	BRAM_EMPTY = (1 << 2)
};

/* error defines */
#define EABFC_FIFO_FULL -1
#define EABFC_FIFO_EMPTY -2
#define EABFC_VALID_NOT_ASSERTED -3

/* max wait time in microseconds to check for data */
#define MAX_US_WAIT 5
#define MAX_WAIT_POLL_VALID_US MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_BRAM_FIFO_CONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void ABFC_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define ABFC_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_BRAM_FIFO_CONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_CONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 ABFC_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define ABFC_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

extern u32  ABFC_get_ctrl_reg(const u32 baseaddr);
extern void ABFC_en_write_en(const u32 baseaddr);
extern void ABFC_den_write_en(const u32 baseaddr);
extern void ABFC_en_clken(const u32 baseaddr);
extern void ABFC_den_clken(const u32 baseaddr);
extern void ABFC_en_read_en(const u32 baseaddr);
extern void ABFC_den_read_en(const u32 baseaddr);
extern void ABFC_en_reset(const u32 baseaddr);
extern void ABFC_den_reset(const u32 baseaddr);

extern u8 ABFC_poll_dout_valid(const u32 baseaddr);
extern u8 ABFC_poll_bram_full(const u32 baseaddr);
extern u8 ABFC_poll_bram_empty(const u32 baseaddr);

extern u32  ABFC_write_data(const u32 baseaddr, const u32 dat);
extern u32  ABFC_read_data(const u32 baseaddr, u32 *datout);
extern void ABFC_read_prep(const u32 baseaddr);
extern void ABFC_print_error(const int err);
extern void ABFC_disable_core(const u32 baseaddr);
extern void ABFC_init_core(const u32 baseaddr);

extern XTime ABFC_get_time(void);
extern XTime ABFC_elapsed_time_us(const XTime startTime);


#endif // AXI_BRAM_FIFO_CONTROLLER_H