#include "tdma_slot_generator.h"
#include "stdio.h"
#include "stdlib.h"
#include "xscugic.h"
#include "platform.h"
#include "time.h"
#include "xil_exception.h"
#include "xil_io.h"
#include "xparameters.h"

/* xparameters.h is not generating the proper address ranges - must hardcore */
#define TDMA_SLOT_GEN_INTR_BASE 0x43c10000 /* from vivado address editor */
#define TDMA_SLOT_GEN_BASE  0x43c00000     /* from vivado address editor */

/* interrupt id for button_interrupt IP Core */
#define TDMA_SLOT_GEN_INTERRUPT_ID   XPAR_FABRIC_TDMA_SLOT_GENERATOR_0_IRQ_INTR

/* define GIC */
#define INTC_DEVICE_ID                  XPAR_PS7_SCUGIC_0_DEVICE_ID

/* parameters matching the IP Cores settings for the GIC */
#define INT_PRIORITY       0xA0

/* instance of the IP Core */
static Xtdma_slot_gen SLOT_GEN_INST;

/* instance of the GIC */
static XScuGic Intc;

/* Function prototypes */
int SetupInterruptSystem();
void rigorous_test();
void infinite_test();
void handler();

/* global interrupt count - reset each new pulse */
static int count = 0;

/* Main */
int main()
{
    init_platform();

    /* enable and reset core */
    printf("\n------------------------------------------------\n\r");
    printf("Enable and Reset tdma_slota_generator IP Core...\n\r");
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | RST_BIT);
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);

    /* get duty cycle / slot duration from core -> calculate number of slots */
    uint32_t duration = TDMA_SLOT_GENERATOR_mReadReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_S00_TDMA_DURATION_DEBUG_OFFSET);
    uint32_t duty = TDMA_SLOT_GENERATOR_mReadReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_S00_TDMA_DUTY_DEBUG_OFFSET);
    int num_slots = 1000/duration; /* 1000 ms / duration of a slot in ms */
    printf("Slot duration : %d ms, Duty Cycle : %d%%\n\r",duration,duty);
    printf("Expect %d interrupt's per input pulse\n\r",num_slots);

    /* enable interrupts */
    printf("Enabling interrupts for new slot pulses\n\r");
    printf("------------------------------------------------\n\r");
    SetupInterruptSystem();

    /* run tests */
//    rigorous_test();
    infinite_test();

	/* disables core and cleans platform */
    printf("\nCleaning up and exiting...\n\r");
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
			TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, 0);
	cleanup_platform();

	return 0;
}

/* infinite loop of pulses w/ 1 sec sleep between them */
void infinite_test()
{
	printf("------------------------------------\n\r");
	printf("Sending infinite back to back pulses\n\r");
	printf("------------------------------------\n\r");
	TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | RST_BIT);

	while(1){
		printf(">>> Pulse simulated...\n\r");
		count = 0;
		TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
				TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  	TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
        TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
		sleep(1);
	}
	return;
}


/* test run through various scenarios */
void rigorous_test()
{
	printf("---------------------------------\n\r");
	printf("Running through various scenarios\n\r");
	printf("---------------------------------\n\r");
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | RST_BIT);
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);

    /* two pulses one second apart */
    printf("\nBack to back pulses\n\r");
	printf(">>> Pulse simulated...\n\r");
	count = 0;
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	sleep(1);
	count = 0;
	printf(">>> Pulse simulated...\n\r");
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	sleep(1);

	/* set en = 0 mid frame */
	printf("\nTest disabling core midway through frame (1/2 s)\n\r");
	printf(">>> Pulse simulated...\n\r");
	count = 0;
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	usleep(500000);
	count = 0;
	printf("Set en = 0\n\r");
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, 0x0);
    sleep(1);

    /* set reset = 1 mid frame */
    printf("\nTest reseting core midway through frame (1/2 s)\n\r");
	printf(">>> Pulse simulated...\n\r");
        TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    				TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
      	TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
            TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	usleep(500000);
	printf("Set reset = 1\n\r");
    TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    		TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | RST_BIT);
    sleep(1);

  /* Simulate pulse while another pulse is still active */
  printf("\nSimulate new pulse while another frame is active (after 1/2s)\n\r");
	printf(">>> Pulse simulated...\n\r");
	count = 0;
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	usleep(500000);
	count = 0;
	printf(">>> Pulse simulated...\n\r");
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	sleep(1);

	/* latch pps signal high for 2 seconds */
	printf("\nLatching pps signal high for 2 seconds\n\r");
	count = 0;
	printf(">>> Pulse simulated...\n\r");
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
      TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT | PPS_BIT);
	sleep(2);
	printf(">>> Pulse released\n\r");
  TDMA_SLOT_GENERATOR_mWriteReg(TDMA_SLOT_GEN_BASE,
    TDMA_SLOT_GENERATOR_STATUS_REG_OFFSET, EN_BIT);
	sleep(1);

	return;
}

/* Enables the GIC and connects the IP Core and Handler */
int SetupInterruptSystem()
{
	int 	xstatus;
	XScuGic	*IntcInstancePtr = &Intc;

	XScuGic_Config *IntcConfig;

	/* Initialize the interrupt controller driver so that it is ready to use. */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	/* IntcInstancePtr Pointer to ScuGic instance */
	xstatus = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (xstatus != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Initialize the exception table and register the interrupt */
	/* controller handler with the exception table */
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				 (Xil_ExceptionHandler)XScuGic_InterruptHandler, IntcInstancePtr);

	/* Enable non-critical exceptions */
	Xil_ExceptionEnable();
	XScuGic_SetPriorityTriggerType(IntcInstancePtr, TDMA_SLOT_GEN_INTERRUPT_ID,
					INT_PRIORITY, TDMA_SLOT_GENERATOR_EDGE_DETECTION);

	/* Connect the interrupt handler that will be called when an */
	/* interrupt occurs for the device. */
	xstatus = XScuGic_Connect(IntcInstancePtr, TDMA_SLOT_GEN_INTERRUPT_ID,
				 (Xil_ExceptionHandler)handler, &SLOT_GEN_INST);
	if (xstatus != XST_SUCCESS) {
		return xstatus;
	}

	/* Enable the interrupt for the CustomIp device. */
	XScuGic_Enable(IntcInstancePtr, TDMA_SLOT_GEN_INTERRUPT_ID);

	/* Enable the interrupts on the Core */
	TDMA_SLOT_GENERATOR_EnableInterrupt(TDMA_SLOT_GEN_INTR_BASE);

	return XST_SUCCESS;
}

/* Exception handler for interrupts */
void handler()
{
  int type = TDMA_SLOT_GENERATOR_mReadReg(TDMA_SLOT_GEN_BASE,TDMA_SLOT_GENERATOR_PULSE_TYPE_OFFSET);
  char buf[100];
  if(type == PULSE_TYPE_GPS)
    sprintf(buf,"new pulse");
  else if(type == PULSE_TYPE_NORM)
    sprintf(buf,"slot pulse");
  else
    sprintf(buf,"unspecified pulse");
	printf("interrupt %03d %s\n\r",count++,buf);
	/* acknowledge interrupt */
	TDMA_SLOT_GENERATOR_ACK(TDMA_SLOT_GEN_INTR_BASE);
	return;
}
