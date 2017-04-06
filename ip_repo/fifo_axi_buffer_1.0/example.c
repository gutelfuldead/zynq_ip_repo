#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "platform.h"
#include <xtime_l.h>
#include "time.h"
#include "fifo_axi_buffer.h"

#define FIFO_AXI_BUFFER_BASE_ADDR 0x43C00000
#define PL_CLK_TIME COUNTS_PER_SECOND/1000000UL

void print(char *str);

XTime get_time(void);
uint32_t elapsed_time_us(XTime startTime);
void wait_pl_tick();
void loopback_test(int data_sz);
void buffer_test(int data_sz);


int main()
{
    init_platform();

    printf("\n\n----------------------------\n\r");
    printf("FIFO_AXI_BUFFER IP CORE TEST\n\r");
    printf("----------------------------\n\r");

    const int data_sz = 64;
    loopback_test(data_sz);
    buffer_test(data_sz);

    cleanup_platform();
    return 0;
}

void buffer_test(int data_sz)
{
	printf("\n------------\n");
	printf("Buffer Test:\n\r");
	printf("------------\n");

	int i, errcnt = 0;
	u16 tx_data[data_sz],rx_data[data_sz];
	for(i = 0; i < data_sz; i++)
		tx_data[i] = (1+i);

    /* SOFT RESET */
	fifo_reset(FIFO_AXI_BUFFER_BASE_ADDR);

	/* WRITE TO FIFO*/
	fifo_write_data(FIFO_AXI_BUFFER_BASE_ADDR,tx_data[0]);
	fifo_set_write(FIFO_AXI_BUFFER_BASE_ADDR);

    for(i = 1; i < data_sz; i++)
    	fifo_write_data(FIFO_AXI_BUFFER_BASE_ADDR,tx_data[i]);
    fifo_disable_write(FIFO_AXI_BUFFER_BASE_ADDR);

	/* READ FROM FIFO */
    fifo_set_read(FIFO_AXI_BUFFER_BASE_ADDR);
/*
 * while((FIFO_AXI_BUFFER_mReadReg(FIFO_BASE_ADDR, FIFO_AXI_BUFFER_S00_AXI_DOUT_REG_OFFSET) & RD_VALID) == 0)
 *		printf("waiting for rd_valid\n");
 */
	for(i = 0; i < data_sz; i++)
		rx_data[i] = fifo_get_data(FIFO_AXI_BUFFER_BASE_ADDR);

	fifo_reset(FIFO_AXI_BUFFER_BASE_ADDR);

	/* report data */
	for(i=0; i < data_sz; i++){
		printf("%03d: tx %03d , rx %03d\n\r",i,tx_data[i],rx_data[i]);
		if(tx_data[i] != rx_data[i])
			errcnt++;
	}
	printf("Number of errors %d\n\r",errcnt);
}

void loopback_test(int data_sz)
{
	printf("\n--------------\n\r");
	printf("Loopback Test:\n\r");
	printf("--------------\n\r");
	int i, errcnt = 0;
	u32 tx_data[data_sz],rx_data[data_sz];
	for(i = 0; i < data_sz; i++)
		tx_data[i] = (1+i);

	fifo_reset(FIFO_AXI_BUFFER_BASE_ADDR);

	/* test fifo */
	fifo_set_read(FIFO_AXI_BUFFER_BASE_ADDR);
	fifo_set_write(FIFO_AXI_BUFFER_BASE_ADDR);
	for(i = 0; i < data_sz; i++){
		fifo_write_data(FIFO_AXI_BUFFER_BASE_ADDR,tx_data[i]);
		rx_data[i] = fifo_get_data(FIFO_AXI_BUFFER_BASE_ADDR);
	}
	fifo_reset(FIFO_AXI_BUFFER_BASE_ADDR);

	/* report data */
	for(i=0; i < data_sz; i++){
		printf("%03d: tx %03d , rx %03d\n\r",i,tx_data[i],rx_data[i]);
		if(tx_data[i] != rx_data[i])
			errcnt++;
	}
	printf("Number of errors %d\n\r",errcnt);
}

XTime
get_time(void)
{
  XTime tmpTime;

  XTime_GetTime(&tmpTime);

  return tmpTime;
}

uint32_t
elapsed_time_us(XTime startTime)
{
  XTime tempXTime;

  tempXTime = get_time();

  tempXTime = tempXTime - startTime;

  tempXTime /= ((COUNTS_PER_SECOND) / 1000000UL);

  return ((uint32_t)tempXTime);
}

void wait_pl_tick()
{
	/* pl clock set to 100MHz */
	uint32_t elapsed = 0;
	XTime strt;
	strt = get_time();
	while(elapsed < PL_CLK_TIME)
		elapsed = elapsed_time_us(strt);
	return;
}
