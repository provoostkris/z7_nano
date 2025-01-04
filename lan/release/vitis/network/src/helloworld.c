
/*
 * helloworld.c: simple test application
 *
 * This application performs some dummy transfers via the FIFO interfaces
 * and writes to the APB slaves
 */

#include <xil_io.h>
#include <sleep.h>

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"


#define AXIS_FIFO_BASE_ADDR 0x43C00000
#define ISR                 0x00000000
#define TDFV                0x0000000C
#define TDFD                0x00000010
#define TLF                 0x00000014
#define RDFO                0x0000001C
#define RDFD                0x00000020
#define RLR                 0x00000024
#define RDR                 0x00000030

#define APB_M1_BASE_ADDR 	0x43C10000
#define APB_M2_BASE_ADDR 	0x43C20000
#define APB_M3_BASE_ADDR 	0x43C30000
#define APB_M4_BASE_ADDR 	0x43C40000

#define XUARTPS_BASE_ADDR   0xE0000000
#define XTTCPS_BASE_ADDR    0xF8001000


void f_fill_reg(u32 addr) {

    u32 wr_data;
	wr_data = 0xff;
	Xil_Out32(addr, wr_data);
}

void f_clear_reg(u32 addr) {

    u32 wr_data;
	wr_data = 0x00;
	Xil_Out32(addr, wr_data);
}

void f_read_reg(u32 addr) {

    u32 rd_data;
	rd_data = Xil_In32(addr);
	xil_printf("REG :%x\n", rd_data);
}

void f_tx_eth() {

    int i;
    u8 data[64];

    //mac_dst
    data[0] = 0x02;
    data[1] = 0x22;
    data[2] = 0x23;
    data[3] = 0x24;
    data[4] = 0x25;
    data[5] = 0x26;
    //mac_src
    data[6]  = 0x06;
    data[7]  = 0x62;
    data[8]  = 0x63;
    data[9]  = 0x64;
    data[10] = 0x65;
    data[11] = 0x66;
    for (i=12; i<64; i++){
    	data[i] = i;
    }

    u32 wr_data;
    u32 rd_data;

	print("AXIS TX dummy packet \n");

		for (i=0; i<64; i=i+4){
			uint32_t wr_data = ((data[i+3]<<24) | (data[i+2]<<16) | (data[i+1]<<8) | (data[i+0]<<0));
			Xil_Out32(AXIS_FIFO_BASE_ADDR + TDFD, wr_data);
		}
		for (i=0; i<64; i=i+1){
			xil_printf("%02x ",data[i]);
			if (i % 8 == 7) {
			  print(" ");
			}
			if (i % 16 == 15) {
			  print("\n");
			}
		}
		print("\n");

		rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+TDFV);
		xil_printf("TDFV:%x\n", rd_data);

		wr_data = 0x40;
		Xil_Out32(AXIS_FIFO_BASE_ADDR + TLF, wr_data);

		rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+ISR);
		xil_printf("ISR :%x\n", rd_data);
}

void f_rx_eth() {

    int i;

    u32 wr_data;
    u32 rd_data;
    u32 rd_fifo_len;
    u8  rd_fifo_dat[1500];

	print("AXIS RX dump packets \n");

	rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+ISR);
	xil_printf("ISR : %x\n", rd_data);

	wr_data = 0x0FFFFFFF;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + ISR, wr_data);

	rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+ISR);
	xil_printf("ISR : %x\n", rd_data);

	rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDFO);
	xil_printf("RDFO:%x\n", rd_data);

	if (rd_data != 0x0) {
		rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RLR);
		xil_printf("RLR :%x\n", rd_data);
		rd_fifo_len = rd_data;

		rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDR);
		xil_printf("RDR: %x\n", rd_data);

		rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDFO);
		xil_printf("RDFO:%x\n", rd_data);

		print(" Packet(s) received : \n");
		for (i=0; i<rd_fifo_len; i=i+4){
			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDFD);
			rd_fifo_dat[i+3] = rd_data>>24;
			rd_fifo_dat[i+2] = rd_data>>16;
			rd_fifo_dat[i+1] = rd_data>>8;
			rd_fifo_dat[i+0] = rd_data>>0;
		}
		for (i=0; i<rd_fifo_len; i=i+1){
			xil_printf("%02x ",rd_fifo_dat[i]);
			if (i % 8 == 7) {
			  print(" ");
			}
			if (i % 16 == 15) {
			  print("\n");
			}
		}
		print("\n");

	} else {
	  print(" Nothing received \n");
	}
}


int main()
{
    init_platform();

    int j;

    for (j=0; j<180; j++){

		f_tx_eth();
		f_rx_eth();
		sleep(1);
		f_fill_reg(APB_M1_BASE_ADDR);
		f_read_reg(APB_M1_BASE_ADDR);
		sleep(1);
		f_clear_reg(APB_M1_BASE_ADDR);
		f_read_reg(APB_M1_BASE_ADDR);

    }

    cleanup_platform();
    return 0;
}
