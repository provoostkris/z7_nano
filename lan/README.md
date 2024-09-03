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
The scrips/modelsim folder contains the reauired do files to be loaded by modelsim.
open modelsim from this location and run the simulate.do file
the first time the vivado is reauired to build the simulation libraries containing the primitives
use gen_sim_libs.tcl in vivado to create these

### Testing
For testing a wireshark is installed on a normal windows laptop.
During installation keep the NPcap option. If not my USB-ETH adapter is not listed.

Plug in the USB-ETH adapter and give it an IP in the free range

Open wireshark and start sniffing.
With a dummy packet , the wireshark is able to recieve 200 Mbps in a setup
FPGA ETH TX >> ETH2USB >> LAN 