

/***************************** Include Files *******************************/
#include "reset_controller.h"

/************************** Function Definitions ***************************/


u32 RST_CTRL_get_ctrl_reg(const u32 baseaddr)
{
	return RESET_CONTROLLER_mReadReg(baseaddr, RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET);
}

void RST_CTRL_system(const u32 baseaddr)
{
	const u32 reg = RST_CTRL_get_ctrl_reg(baseaddr);
	RESET_CONTROLLER_mWriteReg(baseaddr, RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET,
		reg | RST_CTRL_SYS_RESET);
	RESET_CONTROLLER_mWriteReg(baseaddr, RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET,
		reg & ~RST_CTRL_SYS_RESET);
}

extern void RST_CTRL_viterbi(const u32 baseaddr)
{
	const u32 reg = RST_CTRL_get_ctrl_reg(baseaddr);
	RESET_CONTROLLER_mWriteReg(baseaddr, RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET,
		reg | RST_CTRL_VITERBI_RESET);
	RESET_CONTROLLER_mWriteReg(baseaddr, RESET_CONTROLLER_S00_AXI_SLV_REG0_OFFSET,
		reg & ~RST_CTRL_VITERBI_RESET);
}
