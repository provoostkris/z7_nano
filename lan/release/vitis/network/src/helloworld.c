/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <xil_io.h>
#include <sleep.h>

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"


#define AXIS_FIFO_BASE_ADDR 0x43C00000
#define ISR                 0x00000000
#define RDFO                0x0000001C
#define RLR                 0x00000024
#define RDR                 0x00000030


#define XUARTPS_BASE_ADDR   0xE0000000
#define XTTCPS_BASE_ADDR    0xF8001000

int main()
{
    init_platform();

    int i;
    int j;
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

    print("UART 0 regs\n");
    rd_data = Xil_In32(XUARTPS_BASE_ADDR+0x0000);
    xil_printf("%x\n", rd_data);
    print("TTC 0 regs\n");
    rd_data = Xil_In32(XTTCPS_BASE_ADDR+0x0010);
    xil_printf("%x\n", rd_data);


    for (j=0; j<180; j++){

		print("AXIS TX dummy packet \n");

			for (i=0; i<64; i=i+4){
				uint32_t wr_data = ((data[i+3]<<24) | (data[i+2]<<16) | (data[i+1]<<8) | (data[i+0]<<0));
				Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, wr_data);
				xil_printf("%x  : %x\n", i , wr_data);
			}

			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+0x000C);
			xil_printf("%x\n", rd_data);

			wr_data = 0x40;
			Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x14, wr_data);

			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+0x0000);
			xil_printf("%x\n", rd_data);

		print("AXIS RX dump packets \n");

			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+ISR);
			xil_printf("%x\n", rd_data);

			wr_data = 0x0FFFFFFF;
			Xil_Out32(AXIS_FIFO_BASE_ADDR + ISR, wr_data);

			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+ISR);
			xil_printf("%x\n", rd_data);

			rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDFO);
			xil_printf("%x\n", rd_data);

			if (rd_data != 0x0) {
				rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RLR);
				xil_printf("%x\n", rd_data);

				rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDR);
				xil_printf("%x\n", rd_data);

				rd_data = Xil_In32(AXIS_FIFO_BASE_ADDR+RDFO);
				xil_printf("%x\n", rd_data);
			} else {
			  print(" Nothing recieved \n");
			}

		sleep(1);
    }

    cleanup_platform();
    return 0;
}
