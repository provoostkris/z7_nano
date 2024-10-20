# LAN releases


### FPGA release
The FPGA release contains the programming files and hardware handoff files for SW development.
Relevant reports are kept to check the release quality. 

### SW release
The application is just making use of the streaming ports to TX or RX a frame.
The use of the stream handling can be found in [docs/ds806_axi_fifo_mm_s.pdf](docs/ds806_axi_fifo_mm_s.pdf)


### Verification
These frames can be captured with a network traffic sniffer, such as wireshark
The PL design can be instrumendted with internal logic analyzers to capture data processing
Example of TX and RX traffic verified with debugging serial link and wireshark 


![wireshark_02](img/wireshark_02.png)

