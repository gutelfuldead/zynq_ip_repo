#include <stdio.h>
#include "platform.h"
#include "axi_bram_FIFO_controller.h"

#define ABFC_ADDR 0x43c00000
#define TEST_SZ 1000
u32 TX_BUF[TEST_SZ];
u32 RX_BUF[TEST_SZ];

int main()
{
    init_platform();
    ABFC_init_core(ABFC_ADDR);

    int i,cnt,err = 0;

    printf("\n\r==============\n\r");
    printf("BRAM FIFO TEST\n\r");
    printf("==============\n\r");
    printf("bram empty : %d, full : %d\n\r",ABFC_poll_bram_empty(ABFC_ADDR),
            ABFC_poll_bram_full(ABFC_ADDR));


    /* fill fifo */
    for(i = 0; i < TEST_SZ; i++){
    	TX_BUF[i] = i;
    	err = ABFC_write_data(ABFC_ADDR,TX_BUF[i])
        if(err < 0){
            ABFC_print_error(err);
            break;
        }
    }

    /* read fifo */
    ABFC_read_prep(ABFC_ADDR);
    for(i = TEST_SZ-1; i >= 0; i--){
    	err = ABFC_read_data(ABFC_ADDR, &RX_BUF[i])
        if(err < 0){
           ABFC_print_error(err);
           break;
        }
    	else{
			printf("%d : %d\n\r",i,(int)RX_BUF[i]);
			if(RX_BUF[i] != TX_BUF[i])
				cnt++;
    	}
    }

    printf("bram empty : %d, full : %d\n\r",ABFC_poll_bram_empty(ABFC_ADDR),
            ABFC_poll_bram_full(ABFC_ADDR));
    printf("ttl num errors : %d\n\r",cnt);
    printf("Done\n\r");

    ABFC_disable_core(ABFC_ADDR);
    cleanup_platform();
    return 0;
}