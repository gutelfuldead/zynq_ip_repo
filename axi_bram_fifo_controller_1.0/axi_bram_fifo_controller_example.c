#include "axi_bram_fifo_controller.h"
#include <stdio.h>
#include "platform.h"

#define FIFO_ADDR 0x43c00000
#define MAX_SZ 1023

void print(char *str);

int main()
{
    init_platform();
    AFIFO_init_core(FIFO_ADDR);
    u32 TX_BUF[MAX_SZ] = {0};
    u32 RX_BUF[MAX_SZ] = {0};
    int i = 0;
    int errno = 0;
    int errcnt = 0;

    printf("\n\r=======================\n\r");
    printf("AXI BRAM FIFO TEST STRT\n\r");
    printf("=======================\n\r");

    for(i = 0; i < MAX_SZ; i++){
    	TX_BUF[i] = i;
    	errno = AFIFO_write_data(FIFO_ADDR, TX_BUF[i]);
    	if(errno < 0)
    		AFIFO_print_error(errno);
    }

    u32 occupancy = AFIFO_poll_occupancy(FIFO_ADDR);
    printf("\tOccupancy = %d\n\r",(int)occupancy);

	AFIFO_read_prep(FIFO_ADDR);
    for(i=0; i < occupancy; i++){
    	errno = AFIFO_read_data(FIFO_ADDR, &RX_BUF[i]);
    	printf("\ttx[%04d]=%04d | rx[%04d]=%04d\n\r",i,(int)TX_BUF[i],i,(int)RX_BUF[i]);
    	if(errno < 0)
    		AFIFO_print_error(errno);
    	if(RX_BUF[i] != TX_BUF[i]){
    		errcnt++;
    		printf("\terror : tx[%d]=%d rx[%d]=%d\n\r",i,TX_BUF[i],i,RX_BUF[i]);
    	}
    }

    printf("\tError count : %d\n\r",errcnt);
    printf("=======================\n\r");
    printf("AXI BRAM FIFO TEST DONE\n\r");
    printf("=======================\n\r");
    AFIFO_disable_core(FIFO_ADDR);

    cleanup_platform();
    return 0;
}

