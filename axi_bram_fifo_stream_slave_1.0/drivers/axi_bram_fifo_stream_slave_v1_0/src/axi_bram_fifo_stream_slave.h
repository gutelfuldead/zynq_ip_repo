#ifndef AXI_BRAM_FIFO_STREAM_SLAVE_H
#define AXI_BRAM_FIFO_STREAM_SLAVE_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xtime_l.h"

#define ABFSS_CONTROL_REG_OFFSET   0
#define ABFSS_STATUS_REG_OFFSET    4
#define ABFSS_OCCUPANCY_REG_OFFSET 8
#define ABFSS_DATA_OUT_REG_OFFSET  12

typedef enum _control_reg_mask
{
	ABFSS_CLKEN   = (1 << 0),
	ABFSS_RESET   = (1 << 1),
	ABFSS_READ_EN = (1 << 2)
};

typedef enum _status_reg_mask
{
	ABFSS_BRAM_FULL  = (1 << 0),
	ABFSS_BRAM_EMPTY = (1 << 1),
	ABFSS_DVALID     = (1 << 2)
};

#define EABFSS_FIFO_EMPTY -2
#define EABFSS_VALID_NOT_ASSERTED -3

/* max wait time in microseconds to check for data */
#define ABFSS_MAX_US_WAIT 5
#define ABFSS_POLL_VALID_MAX ABFSS_MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_BRAM_FIFO_STREAM_SLAVE register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_STREAM_SLAVEdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define AXI_BRAM_FIFO_STREAM_SLAVE_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_BRAM_FIFO_STREAM_SLAVE register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_BRAM_FIFO_STREAM_SLAVE device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define AXI_BRAM_FIFO_STREAM_SLAVE_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

/************************** Function Prototypes ****************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the AXI_BRAM_FIFO_STREAM_SLAVE instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus AXI_BRAM_FIFO_STREAM_SLAVE_Reg_SelfTest(void * baseaddr_p);

extern u32  ABFSS_get_ctrl_reg(const u32 baseaddr);
extern void ABFSS_en_clken(const u32 baseaddr);
extern void ABFSS_den_clken(const u32 baseaddr);
extern void ABFSS_en_read_en(const u32 baseaddr);
extern void ABFSS_den_read_en(const u32 baseaddr);
extern void ABFSS_en_reset(const u32 baseaddr);
extern void ABFSS_den_reset(const u32 baseaddr);

extern u8 ABFSS_poll_dout_valid(const u32 baseaddr);
extern u8 ABFSS_poll_bram_full(const u32 baseaddr);
extern u8 ABFSS_poll_bram_empty(const u32 baseaddr);
extern u32 ABFSS_poll_occupancy(const u32 baseaddr);

extern u32  ABFSS_read_data(const u32 baseaddr, u32 *datout);

extern void ABFSS_disable_core(const u32 baseaddr);
extern void ABFSS_init_core(const u32 baseaddr);

extern XTime ABFSS_get_time(void);
extern XTime ABFSS_elapsed_time_us(const XTime startTime);

#endif // AXI_BRAM_FIFO_STREAM_SLAVE_H
