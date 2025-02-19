set_property PACKAGE_PIN N18 [get_ports clk]
set_property PACKAGE_PIN P14 [get_ports reset_n]
set_property PACKAGE_PIN R14 [get_ports led]
set_property PACKAGE_PIN T17 [get_ports pll_lock]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports pll_lock]

set_property PACKAGE_PIN K17 [get_ports rgmii_rxc]
set_property PACKAGE_PIN K18 [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN M17 [get_ports {rgmii_rd[3]}]
set_property PACKAGE_PIN M18 [get_ports {rgmii_rd[2]}]
set_property PACKAGE_PIN K14 [get_ports {rgmii_rd[1]}]
set_property PACKAGE_PIN J14 [get_ports {rgmii_rd[0]}]
set_property PACKAGE_PIN L14 [get_ports rgmii_txc]
set_property PACKAGE_PIN N16 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN N15 [get_ports {rgmii_td[3]}]
set_property PACKAGE_PIN M15 [get_ports {rgmii_td[2]}]
set_property PACKAGE_PIN L15 [get_ports {rgmii_td[1]}]
set_property PACKAGE_PIN M14 [get_ports {rgmii_td[0]}]
set_property PACKAGE_PIN L19 [get_ports phy_rst_n]

set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rxc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rd[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_td[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]