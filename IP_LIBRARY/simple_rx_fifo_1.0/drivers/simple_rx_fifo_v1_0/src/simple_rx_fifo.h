
#ifndef SIMPLE_RX_FIFO_H
#define SIMPLE_RX_FIFO_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xtime_l.h"
#include "xstatus.h"
#include "xil_assert.h"
#include "xil_types.h"

#define SIMPLE_RX_FIFO_CONTROL_REG0_OFFSET 0
#define SIMPLE_RX_FIFO_STATUS_REG1_OFFSET 4
#define SIMPLE_RX_FIFO_OCCUPANCY_REG2_OFFSET 8
#define SIMPLE_RX_FIFO_DATA_OUT_REG3_OFFSET 12
#define SIMPLE_RX_FIFO_IRQ_LEVEL_REG4_OFFSET 16
#define SIMPLE_RX_FIFO_S00_AXI_SLV_REG5_OFFSET 20
#define SIMPLE_RX_FIFO_S00_AXI_SLV_REG6_OFFSET 24
#define SIMPLE_RX_FIFO_S00_AXI_SLV_REG7_OFFSET 28

/* control register bit masks */
#define SRXFIFO_CLK_EN_BIT_MASK     (1 << 0)
#define SRXFIFO_RESET_BIT_MASK      (1 << 1)
#define SRXFIFO_READ_EN_BIT_MASK    (1 << 2)
#define SRXFIFO_READ_DONE_BIT_MASK  (1 << 3)
#define SRXFIFO_IRQ_EN_BIT_MASK     (1 << 4)

/* status register bit masks */
#define SRXFIFO_BRAM_FULL_BIT_MASK  (1 << 0)
#define SRXFIFO_BRAM_EMPTY_BIT_MASK (1 << 1)
#define SRXFIFO_DATA_VALID_BIT_MASK (1 << 2)

#define ESRXFIFO_EMPTY -1
#define ESRXFIFO_VALID_NOT_ASSERTED -2

/* max wait time in microseconds to check for data */
#define SRXFIFO_MAX_US_WAIT 5
#define SRXFIFO_POLL_VALID_MAX SRXFIFO_MAX_US_WAIT / ((COUNTS_PER_SECOND) / 1000000UL)

#define SRXFIFO_EDGE_DETECTION 0x3  /* rising edge detection */

typedef struct {
	u16 DeviceId;		/* Unique ID  of device */
	UINTPTR BaseAddress;	/* Device base address */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xsrxfifo_config;

typedef struct {
	UINTPTR BaseAddress;	/* Device base address */
	u32 IsReady;		/* Device is initialized and ready */
	int InterruptPresent;	/* Are interrupts supported in h/w */
} Xsrxfifo;

/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a SIMPLE_RX_FIFO register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the SIMPLE_RX_FIFOdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void SIMPLE_RX_FIFO_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define SIMPLE_RX_FIFO_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a SIMPLE_RX_FIFO register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the SIMPLE_RX_FIFO device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 SIMPLE_RX_FIFO_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define SIMPLE_RX_FIFO_mReadReg(BaseAddress, RegOffset) \
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
 * @param   baseaddr_p is the base address of the SIMPLE_RX_FIFO instance to be worked on.
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
XStatus SIMPLE_RX_FIFO_Reg_SelfTest(void * baseaddr_p);

extern u32  SRXFIFO_get_ctrl_reg(const u32 baseaddr);
extern void SRXFIFO_en_clken(const u32 baseaddr);
extern void SRXFIFO_den_clken(const u32 baseaddr);
extern void SRXFIFO_en_read_en(const u32 baseaddr);
extern void SRXFIFO_den_read_en(const u32 baseaddr);
extern void SRXFIFO_en_reset(const u32 baseaddr);
extern void SRXFIFO_den_reset(const u32 baseaddr);

extern u8 SRXFIFO_poll_dout_valid(const u32 baseaddr);
extern u8 SRXFIFO_poll_bram_full(const u32 baseaddr);
extern u8 SRXFIFO_poll_bram_empty(const u32 baseaddr);
extern u32 SRXFIFO_poll_occupancy(const u32 baseaddr);

void SRXFIFO_write_interrupt_level(const u32 baseaddr, const u32 interrupt_level);

extern u32  SRXFIFO_read_data(const u32 baseaddr, u32 *datout);
extern void SRXFIFO_read_done(const u32 baseaddr);

extern void SRXFIFO_disable_core(const u32 baseaddr);
extern void SRXFIFO_init_core(const u32 baseaddr);

extern XTime SRXFIFO_get_time(void);
extern XTime SRXFIFO_elapsed_time_us(const XTime startTime);

extern void SRXFIFO_irq_en(const u32 baseaddr);
extern void SRXFIFO_irq_den(const u32 baseaddr);

extern void SRXFIFO_EnableInterrupt(void * baseaddr_p);
extern void SRXFIFO_ACK(void * baseaddr_p);
extern int XSRXFIFO_CfgInitialize(Xsrxfifo * InstancePtr, Xsrxfifo_config * Config,
			UINTPTR EffectiveAddr);

#endif // SIMPLE_RX_FIFO_H
