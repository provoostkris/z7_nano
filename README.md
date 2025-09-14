# 🧠 Z7-nano FPGA Experiments
**Microphase Z7-nano with Xilinx Zynq-7020 SoC**

Welcome to a hands-on collection of FPGA experiments using the **Microphase Z7-nano** development board. This repo is designed to help you explore the capabilities of the **Microphase Z7-nano**

Note that the **Microphase Z7-nano** can be ordered in the variant with **Zynq-7020 SoC** or **Zynq-7010 SoC** for these demo projects, the **Zynq-7020 SoC** is used.

## 🧠 About the Board

- **Board**: Microphase Z7-nano
- **FPGA**: Xilinx Zynq-7020 SoC
  - Dual-core ARM Cortex-A9
  - 53,200 LUTs, 106,400 Flip-Flops
- **Interfaces & components**:
 - see [Documentation folder](/docs) for more information

## 🧰 What Is This Project About?

This repository contains several small hardware experiments that:
- Use the **FPGA fabric** to control LEDs, HDMI, Ethernet, PMODs , etc
- Demonstrate **communication between the ARM processor and the FPGA**
- Help you learn how to use **VHDL** to get functions running on the board

## 🔍 Examples list

| Folder         | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| [docs](./docs)        | Board documentation and reference materials |
| [hdmi_tx](./hdmi_tx/)     | HDMI video output using onboard connector |
| [img](./img/)         | Diagrams and screenshots |
| [lan](./lan/)         | Wired Ethernet over RGMII using programmable logic |
| [led_blink](./led_blink/)   | Various LED blinking  perfect for first-time board testing |
| [pl_eth_udp](./pl_eth_udp/)  | UDP communication via PL Ethernet |
| [pmod](./pmod/)        | Simple PMOD interface examples |

## 💖 Support This Project

If you find VLink useful and would like to support its development, consider making a donation:

- [☕ Buy Me a Coffee](https://www.buymeacoffee.com/provoostkris)
- [❤️ GitHub Sponsors](https://github.com/sponsors/provoostkris)

Your support helps keep the project alive and evolving. Thank you!
