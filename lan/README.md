# LAN design

### Description
Make use of the *ETH PORT* connected via the PL fabric. The design makes use of an RGMII interface.
*DDR I/O* is used for dubble edge sampling. The reference frequency is multiplied by an embedded PLL.
Frequency is fixed to perform at 1 Gbps. 

### Features
PHY : 1 Gbps


### [I/O](constraints)
- PL ETH 
- LED : 
  - off = reset
  - on  = active
- RESET button press = send a dummy frame


### Simulation
The [scrips/modelsim](scrips/modelsim/) folder contains the required do files to be loaded by modelsim.
  - Open modelsim from this location 
  - Run the simulate.do file
Note : The first time the simulation is started, the vivado is required to build the simulation libraries containing the primitives
to do this , use gen_sim_libs.tcl in [scrips/vivado](scrips/vivado/) to create the xilinx libraries

### Releasing
The [scrips/vivado](scrips/vivado/) folder contains the required tcl files to be loaded by vivado.
  - Open vivado 
  - Select run script from the menu
  - Select build.tcl
Note : The first time the build is started, the block design must be generated
to do this , use bd_base.tcl in [scrips/vivado/](scrips/vivado/) to create the base block design

### Testing
For testing a [wireshark](https://www.wireshark.org/) is installed on a normal windows laptop.
During installation keep the NPcap option. If not my USB-ETH adapter is not listed.

Plug in the USB-ETH adapter and give it an IP in the free range.

Open wireshark and start sniffing.
With a dummy packet , the wireshark is able to recieve about 200 Mbps in a setup
FPGA ETH TX >> ETH2USB >> LAN 