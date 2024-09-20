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

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"


#define AXIS_FIFO_BASE_ADDR 0x43C00000
#define XUARTPS_BASE_ADDR   0xE0000000
#define XTTCPS_BASE_ADDR    0xF8001000

int main()
{
    init_platform();

    u32 data;

    print("UART 0 regs\n");
    data = Xil_In32(XUARTPS_BASE_ADDR+0x0000);
    xil_printf("%x\n", data);
    print("TTC 0 regs\n");
    data = Xil_In32(XTTCPS_BASE_ADDR+0x0010);
    xil_printf("%x\n", data);

    print("AXIS TX 64 bytes \n");
    data = 0x11111111;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
    data = 0x22222222;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
    data = 0x33333333;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
    data = 0x44444444;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x10, data);

    data = Xil_In32(AXIS_FIFO_BASE_ADDR+0x000C);
    xil_printf("%x\n", data);

    data = 0x40;
	Xil_Out32(AXIS_FIFO_BASE_ADDR + 0x14, data);

    data = Xil_In32(AXIS_FIFO_BASE_ADDR+0x0000);
    xil_printf("%x\n", data);

    cleanup_platform();
    return 0;
}
