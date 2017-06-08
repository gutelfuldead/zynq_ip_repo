#include "axi_bram_fifo_controller.h"
#include <stdio.h>
#include "platform.h"

#define FIFO_ADDR 0x43c00000
#define MAX_SZ 1024
#define TEST_SZ 1020
//#define VERBOSE

int addr_loop_around_test(u32 *TX_BUF, u32 *RX_BUF);
int stress_test(u32 *TX_BUF, u32 *RX_BUF);
int overflow_fifo();
int underflow_fifo();

int main()
{
    init_platform();
    u32 TX_BUF[TEST_SZ] = {0};
    u32 RX_BUF[TEST_SZ] = {0};
    int status = XST_SUCCESS;

    printf("\n\r=======================\n\r");
    printf("AXI BRAM FIFO TEST STRT\n\r");
    printf("=======================\n\r");

    /* test core's ability to loop the address and read pointers */
    status = addr_loop_around_test(&TX_BUF, &RX_BUF);
    if(status == XST_FAILURE)
    	printf("\t!! Core Address failed to loop from max back to zero\n\r");
    else
    	printf("\t!! Success !!\n\r");

    /* test core's ability to alternate between read and writes w/o losing data */
    status = stress_test(&TX_BUF, &RX_BUF);
    if(status == XST_FAILURE)
    	printf("\t!! Core failed alternate read writes\n\r");
    else
    	printf("\t!! Success !!\n\r");

    /* test core's ability to prevent overflow */
    status = overflow_fifo();
    if(status == XST_FAILURE)
    	printf("\t!! Core failed to stop writing when FIFO full\n\r");
    else
    	printf("\t!! Success !!\n\r");

    /* test core's ability to prevent underflow */
    status = underflow_fifo();
    if(status == XST_FAILURE)
    	printf("\t!! Core failed to stop reading when FIFO empty\n\r");
    else
    	printf("\t!! Success !!\n\r");

    if(status == XST_FAILURE)
    	printf("\n\r!! TEST FAILED !!\n\n\r");
    else
    	printf("\n\r\t!! TEST SUCCESSFUL !!\n\n\r");

    printf("=======================\n\r");
    printf("AXI BRAM FIFO TEST DONE\n\r");
    printf("=======================\n\r");

    cleanup_platform();
    return 0;
}

int underflow_fifo()
{
    AFIFO_init_core(FIFO_ADDR);
	printf("\n\r\tTesting underflowing the FIFO...\n\r");
	int status = XST_FAILURE;
	u32 test;
	int errno = 0;
	errno = AFIFO_read_data(FIFO_ADDR, &test);
	if(errno == EAFIFO_FIFO_EMPTY){
		status = XST_SUCCESS;
	}
    AFIFO_disable_core(FIFO_ADDR);
	return status;
}

int overflow_fifo()
{
	printf("\n\r\tTesting overflowing the FIFO...\n\r");
    AFIFO_init_core(FIFO_ADDR);
	int overload_sz = MAX_SZ + 1;
	u32 TX_BUF[overload_sz];
	int i = 0;
	int errno = 0;
	int status = XST_FAILURE;

	for(i = 0; i < overload_sz; i++){
		errno = AFIFO_write_data(FIFO_ADDR, TX_BUF[i]);
		if(errno == EAFIFO_FIFO_FULL){
			status = XST_SUCCESS;
		}
	}
    AFIFO_disable_core(FIFO_ADDR);
	return status;
}

int stress_test(u32 *TX_BUF, u32 *RX_BUF)
{
    AFIFO_init_core(FIFO_ADDR);
	int status = XST_SUCCESS;
	int i,j,k = 0;
	int errno = 0;
	int errcnt = 0;
	u32 occupancy = 0;
	const int write_cnt = 10;
	const int read_cnt = 5;
	u32 old_rx = 0;

    printf("\n\r\tTesting switching from read to write before emptying FIFO...\n\r");

	for(i = 0; i < TEST_SZ; i++)
		TX_BUF[i] = i;

	for(i = 0; i < TEST_SZ/write_cnt; i++){
		// write
		for(j = 0; j < write_cnt; j++){
			errno = AFIFO_write_data(FIFO_ADDR, TX_BUF[i*write_cnt+j]);
			if(errno < 0){
				AFIFO_print_error(errno);
				status = XST_FAILURE;
			}
		}
		// read
		for(k = 0; k < read_cnt; k++){
			errno = AFIFO_read_data(FIFO_ADDR, &RX_BUF[k]);
#ifdef VERBOSE
			printf("\trx[%04d]=%04d\n\r",k,(int)RX_BUF[k]);
#endif
			if(errno < 0){
				AFIFO_print_error(errno);
				status = XST_FAILURE;
			}
			if(i != 0 && RX_BUF[k] != old_rx + 1){
				errcnt++;
			}
			old_rx = RX_BUF[k];

		}
		occupancy = AFIFO_poll_occupancy(FIFO_ADDR);
#ifdef VERBOSE
		printf("\titeration %d : occupancy %d\n\r",i,occupancy);
#endif
	}
#ifdef VERBOSE
	printf("\tNumber of errors %d\n\r",errcnt);
#endif
	if(errcnt > 0)
		status = XST_FAILURE;

    AFIFO_disable_core(FIFO_ADDR);
	return status;
}

int addr_loop_around_test(u32 *TX_BUF, u32 *RX_BUF)
{
    AFIFO_init_core(FIFO_ADDR);
    printf("\n\r\tTesting rd/wr address pointer loop around...\n\r");
    int i, j = 0;
    int status = XST_SUCCESS;
    int errno = 0;
    int errcnt = 0;
    u32 occupancy = 0;

    for(j = 0 ; j < TEST_SZ; j++){
#ifdef VERBOSE
    	printf("\tIteration %d\n\r",j);
#endif
		for(i = 0; i < TEST_SZ; i++){
			TX_BUF[i] = i;
			errno = AFIFO_write_data(FIFO_ADDR, TX_BUF[i]);
			if(errno < 0){
				AFIFO_print_error(errno);
				status = XST_FAILURE;
			}
		}
		occupancy = AFIFO_poll_occupancy(FIFO_ADDR);
#ifdef VERBOSE
		printf("\tOccupancy = %d\n\r",(int)occupancy);
#endif
		for(i=0; i < occupancy; i++){
			errno = AFIFO_read_data(FIFO_ADDR, &RX_BUF[i]);
			if(errno < 0)
				AFIFO_print_error(errno);
			if(RX_BUF[i] != TX_BUF[i]){
				errcnt++;
#ifdef VERBOSE
				printf("\terror : tx[%d]=%d rx[%d]=%d\n\r",i,(int)TX_BUF[i],i,(int)RX_BUF[i]);
#endif
				status = XST_FAILURE;
			}
		}
#ifdef VERBOSE
		printf("\tError count : %d\n\r",errcnt);
#endif
   }
   AFIFO_disable_core(FIFO_ADDR);
   return status;
}

