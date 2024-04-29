create_clock -period 20.000       [get_ports clk]

set_property PACKAGE_PIN N18      [get_ports clk]
set_property PACKAGE_PIN P14      [get_ports reset_n]
set_property PACKAGE_PIN R14      [get_ports led]

set_property IOSTANDARD LVCMOS33  [get_ports reset_n]
set_property IOSTANDARD LVCMOS33  [get_ports led]
set_property IOSTANDARD LVCMOS33  [get_ports clk]