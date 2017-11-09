#include "xparameters.h"
#include "xil_exception.h"
#include "xstatus.h"
#include "stdio.h"
#include "stdlib.h"
#include "axi_master_stream_fifo.h"
#include "axi_slave_stream_fifo.h"
#include "platform.h"

#define TX_FIFO_ADDR 0X43C00000
#define RX_FIFO_ADDR 0X43C10000

#define MAX_PACKETS 10
#define WORDS_PER_PACKET 20
#define WORD_SZ_BYTES 4

#define V

int tx(const int nwords);
int rx(int * const errcnt, int * const nbytes);

int main(void)
{
	printf("begin fifo test\n\r");
	AMSF_init_core(TX_FIFO_ADDR);
	ASSF_init_core(RX_FIFO_ADDR);

	int packets, nerrors, status, nwords;
	for(packets = 1; packets < MAX_PACKETS; packets++){
		int words = packets*WORDS_PER_PACKET;
		printf("Sent %d words to tx fifo\n\r",words);
		status = tx(words);
		if(status != XST_SUCCESS)
			return XST_FAILURE;
		while(ASSF_poll_occupancy(RX_FIFO_ADDR) < words){
#ifdef V
		printf("tx fifo occ = %d : rx fifo occ = %d\n\r", (int)AMSF_poll_occupancy(TX_FIFO_ADDR),(int)ASSF_poll_occupancy(RX_FIFO_ADDR));
#endif
		}
		status = rx(&nerrors, &nwords);
		if(status != XST_SUCCESS){
			return XST_FAILURE;
		}
		printf("Received %d words w/ %d errors\n\r",nwords,nerrors);
		if(nerrors > 0)
			return XST_FAILURE;
	}
}

tx(const int nwords)
{
	int i, status;
	for(i = 0; i < nwords; i++){
		uint32_t tmp = i;
		status = AMSF_write_data(TX_FIFO_ADDR, tmp);
		if(status != XST_SUCCESS){
			printf("Error writing to tx fifo\n\r");
			return XST_FAILURE;
		}
	}
	AMSF_write_commit(TX_FIFO_ADDR);
	return XST_SUCCESS;
}

rx(int * const errcnt, int * const nbytes)
{
	int i, status;
	int errors = 0;
	u32 occ = ASSF_poll_occupancy(RX_FIFO_ADDR);
	printf("rx occ = %lu\n\r",ASSF_poll_occupancy(RX_FIFO_ADDR));
	for(i = 0; i < occ; i++){
		uint32_t tmp;
		status = ASSF_read_data(RX_FIFO_ADDR, &tmp);
		if(status != XST_SUCCESS){
			printf("Error reading from rx fifo: %s\n\r",
				status == EASSF_FIFO_EMPTY ? "Fifo empty" : "valid not asserted");
			return XST_FAILURE;
		}
		else if(tmp != i)
			errors++;
		#ifdef V
		printf("tx[%03d] = %03d : rx[%03d] = %03d%s\n\r",
			i,i,i,tmp, tmp != i ? "-- ERROR" : "");
		#endif
	}
	*errcnt = errors;
	*nbytes = occ;
	return XST_SUCCESS;
}
