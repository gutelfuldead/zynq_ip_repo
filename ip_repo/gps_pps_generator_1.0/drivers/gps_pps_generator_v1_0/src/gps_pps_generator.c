

/***************************** Include Files *******************************/
#include "gps_pps_generator.h"

/************************** Function Definitions ***************************/

/**
 * enables gps_pps_generator_v1
 */
void gps_pps_generator_enable(u32 GPS_PPS_GENERATOR_BASE_ADDR)
{
  GPS_PPS_GENERATOR_mWriteReg(GPS_PPS_GENERATOR_BASE_ADDR,
      GPS_PPS_GENERATOR_CONFIG_REGISTER_OFFSET, gps_pps_sim_EN);
  return;
}

/**
 * performs soft reset on gps_pps_generator_v1
 */
void gps_pps_generator_soft_reset(u32 GPS_PPS_GENERATOR_BASE_ADDR)
{
  GPS_PPS_GENERATOR_mWriteReg(GPS_PPS_GENERATOR_BASE_ADDR,
      GPS_PPS_GENERATOR_CONFIG_REGISTER_OFFSET, gps_pps_sim_EN | gps_pps_sim_RST);
  
  GPS_PPS_GENERATOR_mWriteReg(GPS_PPS_GENERATOR_BASE_ADDR,
      GPS_PPS_GENERATOR_CONFIG_REGISTER_OFFSET, gps_pps_sim_EN);
  return;
}

/**
 * disables gps_pps_generator_v1
 */
void gps_pps_generator_disable(u32 GPS_PPS_GENERATOR_BASE_ADDR)
{
  GPS_PPS_GENERATOR_mWriteReg(GPS_PPS_GENERATOR_BASE_ADDR,
      GPS_PPS_GENERATOR_CONFIG_REGISTER_OFFSET, 0x0);
  return;
}