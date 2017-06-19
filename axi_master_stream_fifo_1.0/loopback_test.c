#include "axi_master_stream_fifo.h"
#include "axi_slave_stream_fifo.h"
#include <stdio.h>
#include <stdlib.h>
#include "platform.h"

#define MASTER_ADDR 0X43C00000
#define SLAVE_ADDR  0X43C30000
#define BUF_SZ 1023
#define TEST_SZ 10

#define NUM_TESTS 4

int simple_read_write();
int overflow_master_buffer();
int underflow_slave_buffer();
int stress_test();

void print_errors(const int errno);

int main()
{
    init_platform();
    printf("\n\r===============================\n\r");
    printf("START FIFO STREAM LOOPBACK TEST\n\r");
    printf("===============================\n\n\r");

    int status[NUM_TESTS] = {XST_FAILURE};
    int tstidx = 0;
    int end_status = XST_SUCCESS;

    status[tstidx] = simple_read_write();
    if(status[tstidx] == XST_FAILURE)
    	printf("\t!! Simple Read Write Test Failed !!\n\n\r");
    else
    	printf("\t!! Simple Read Write Test Passed !!\n\n\r");

    status[++tstidx] = overflow_master_buffer();
    if(status[tstidx] == XST_FAILURE)
    	printf("\t!! Overflow Test Failed !!\n\n\r");
    else
    	printf("\t!! Overflow Test Passed !!\n\n\r");

    status[++tstidx] = underflow_slave_buffer();
    if(status[tstidx] == XST_FAILURE)
    	printf("\t!! Underflow Test Failed !!\n\n\r");
    else
    	printf("\t!! Underflow Test Passed !!\n\n\r");

    status[++tstidx] = stress_test();
    if(status[tstidx] == XST_FAILURE)
    	printf("\t!! Stress Test Failed !!\n\n\r");
    else
    	printf("\t!! Stress Test Passed !!\n\n\r");

    for(tstidx=0; tstidx < NUM_TESTS; tstidx++){
    	if(status[tstidx] == XST_FAILURE){
    		end_status = XST_FAILURE;
    	}
    }

    if(end_status == XST_SUCCESS)
    	printf("\t!! All Tests Passed !!\n\r");
    else
    	printf("\t!! Overall Test Failed !!\n\r");

    printf("\n=============================\n\r");
    printf("END FIFO STREAM LOOPBACK TEST\n\r");
    printf("=============================\n\n\r");
    cleanup_platform();
    return 0;
}

int stress_test()
{
	/* initialize cores */
	AMSF_init_core(MASTER_ADDR);
	ASSF_init_core(SLAVE_ADDR);

	int status = XST_SUCCESS;
	int i = 0;
	u32 tmp = 0;
	int errno = 0;
	int errcnt = 0;
	int max_iterations = 1000000;

	printf("\tStress Test will perform consecutive read/writes until an error occurs or %d iterations\n\r",max_iterations);

	while(status == XST_SUCCESS || i > max_iterations){

		/* write */
		errno = AMSF_write_data(MASTER_ADDR, i);
		if(errno < 0){
			print_errors(errno);
			status = XST_FAILURE;
		}
		/* read */
		errno = ASSF_read_data(SLAVE_ADDR, &tmp);
		if(errno < 0){
			print_errors(errno);
			status = XST_FAILURE;
		}
		/* check */
		if(tmp != i){
			errcnt++;
			status = XST_FAILURE;
		}
		if(i == max_iterations){
			printf("\t\tTest completed with no under/over flows with %d iterations\n\r",i);
		}
		i++;
	}

	printf("\t\tNumber of Errors : %d\n\r",errcnt);
	printf("\t\tTest finished at %d iterations\n\r",i);

	/* disable cores */
	AMSF_disable_core(MASTER_ADDR);
	ASSF_disable_core(SLAVE_ADDR);

	return status;
}

int underflow_slave_buffer()
{
	printf("\tReading slave buffer before being written to...\n\r");
	/* initialize cores */
	AMSF_init_core(MASTER_ADDR);
	ASSF_init_core(SLAVE_ADDR);

	int status = XST_FAILURE;
	u32 tmp = 0;
	int errno = 0;

	while(status == XST_FAILURE){
		errno = ASSF_read_data(SLAVE_ADDR, &tmp);
		if(errno == EASSF_FIFO_EMPTY){
			status = XST_SUCCESS;
			printf("\t\tSlave buffer empty\n\r");
		}
	}

	/* disable cores */
	AMSF_disable_core(MASTER_ADDR);
	ASSF_disable_core(SLAVE_ADDR);

	return status;
}

int overflow_master_buffer()
{
	printf("\tTesting overflowing the master buffer\n\r");
	/* initialize cores */
	AMSF_init_core(MASTER_ADDR);
	ASSF_init_core(SLAVE_ADDR);

	int status = XST_FAILURE;
	int i = 0;
	int errno = 0;

	while(status == XST_FAILURE){
		errno = AMSF_write_data(MASTER_ADDR, i);
		if(errno == EAMSF_FIFO_FULL){
			status = XST_SUCCESS;
			printf("\t\tOverflowed at i = %d (should be BRAM_DEPTH*2)\n\r",i);
		}
		i++;
	}

	AMSF_disable_core(MASTER_ADDR);
	ASSF_disable_core(SLAVE_ADDR);

	return status;

}

int simple_read_write()
{
	printf("\tSimple read/write test; filling fifo with %d elements\n\r",TEST_SZ);

	int status = XST_SUCCESS;
	int i = 0;
	int errcnt = 0;
	int errno = 0;
	u32 tx_buf[BUF_SZ];
	u32 rx_buf[BUF_SZ];
	u32 occ = 0;

	/* initialize cores */
	AMSF_init_core(MASTER_ADDR);
	ASSF_init_core(SLAVE_ADDR);

	/* fill buffers */
	for(i = 0; i < TEST_SZ; i++){
		tx_buf[i] = i + 68;
		rx_buf[i] = 0;
	}

	/* write to master interface */
	printf("\t\tWriting %d items to master interface...\n\r",(int)TEST_SZ);
	for(i = 0; i < TEST_SZ; i++){
		printf("\t\twrite : %d\n\r",(int)tx_buf[i]);
		errno = AMSF_write_data(MASTER_ADDR, tx_buf[i]);
		if(errno < 0){
			status = XST_FAILURE;
			print_errors(errno);
		}
	}

	/* read from slave interface */
	occ = ASSF_poll_occupancy(SLAVE_ADDR);
	if(occ != TEST_SZ){
		printf("\t\tSlave occupancy %d != %d words written...\n\r",(int)occ, TEST_SZ);
//		return XST_FAILURE;
	}

	printf("\t\tReading %d items found in slave interface...\n\r",(int)occ);
	for(i = 0; i < occ; i++){
		errno = ASSF_read_data(SLAVE_ADDR, &rx_buf[i]);
		printf("\t\tread : %d\n\r",(int)rx_buf[i]);
		if(errno < 0){
			status = XST_FAILURE;
			print_errors(errno);
		}
		if(rx_buf[i] != tx_buf[i]){
			errcnt++;
			status = XST_FAILURE;
		}
	}

	printf("\t\tNumber of errors : %d\n\r",errcnt);

	/* disable cores */
	AMSF_disable_core(MASTER_ADDR);
	ASSF_disable_core(SLAVE_ADDR);

	return status;

}

void print_errors(const int errno)
{
	switch(errno){
    case EASSF_FIFO_EMPTY :
        printf("\t\tError : reading FIFO empty\n\r");
        break;
    case EASSF_VALID_NOT_ASSERTED :
        printf("\t\tError : Valid not asserted within %d us\n\r",ASSF_MAX_US_WAIT);
        break;
    case EAMSF_FIFO_FULL :
    	printf("\t\tError : FIFO is full and could not be written to\n\r");
    	break;
	}
}
