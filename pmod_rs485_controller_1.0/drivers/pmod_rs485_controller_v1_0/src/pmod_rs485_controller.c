

/***************************** Include Files *******************************/
#include "pmod_rs485_controller.h"
#include "xil_types.h"

/************************** Function Definitions ***************************/

/**
 * Enables the pmod rs485 controller
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_enable(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg | EN);
	return;
}

/**
 * disables the pmod rs485 controller
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_disable(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg & ~EN);
	return;
}

/**
 * enables the pmod rs485 read enable pin
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_enable_rd(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg | RE);
	return;
}

/**
 * disables the pmod rs485 read enable pin
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_disable_rd(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg & ~RE);
	return;
}

/**
 * enables the pmod rs485 write enable pin
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_enable_wr(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);		
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg | DE);
	return;
}

/**
 * disables the pmod rs485 write enable pin
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_disable_wr(const int baseaddr)
{
	u32 reg = pmod_rs485_controller_get_control_reg(baseaddr);
	PMOD_RS485_CONTROLLER_mWriteReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET, reg & ~DE);
	return;
}

/**
 * capture the current control register
 * @param  baseaddr ip core base addr
 * @return          the (u32) control register
 */
u32  pmod_rs485_controller_get_control_reg(const int baseaddr)
{
	return PMOD_RS485_CONTROLLER_mReadReg((u32)baseaddr, PMOD_RS485_CONTROLLER_CONTROL_REGISTER_OFFSET);
}

/**
 * clears all settings in the control register
 * @param baseaddr ip core base addr
 */
void pmod_rs485_controller_clear_control_reg(const int baseaddr)
{
	pmod_rs485_controller_disable(baseaddr);
	pmod_rs485_controller_disable_wr(baseaddr);
	pmod_rs485_controller_disable_rd(baseaddr);
	return;
}
