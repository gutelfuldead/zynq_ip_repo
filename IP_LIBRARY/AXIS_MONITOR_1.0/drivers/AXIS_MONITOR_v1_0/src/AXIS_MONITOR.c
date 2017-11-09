

/***************************** Include Files *******************************/
#include "AXIS_MONITOR.h"

/************************** Function Definitions ***************************/
extern void AXIS_MON_reset(const u32 baseaddr)
{
	AXIS_MONITOR_mWriteReg(baseaddr, AXIS_MONITOR_RESET_REG, 0x1);
	AXIS_MONITOR_mWriteReg(baseaddr, AXIS_MONITOR_RESET_REG, 0x0);
}

extern u32  AXIS_MON_get_tvalid_cnt(const u32 baseaddr)
{
	return AXIS_MONITOR_mReadReg(baseaddr, AXIS_MONITOR_TVALID_REG);
}

extern u32  AXIS_MON_get_tuser_bit_cnt(const u32 baseaddr)
{
	return AXIS_MONITOR_mReadReg(baseaddr, AXIS_MONITOR_TUSER_BIT_REG);
}
