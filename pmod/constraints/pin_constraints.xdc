create_clock -period 20.000 [get_ports clk]


set_property PACKAGE_PIN N18 [get_ports clk]
set_property PACKAGE_PIN P14 [get_ports reset_n]
set_property PACKAGE_PIN R14 [get_ports led]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports led]

## PMOD LED
set_property PACKAGE_PIN N17 [get_ports {leds[7]}]
set_property PACKAGE_PIN R16 [get_ports {leds[6]}]
set_property PACKAGE_PIN T17 [get_ports {leds[5]}]
set_property PACKAGE_PIN T16 [get_ports {leds[4]}]
set_property PACKAGE_PIN W18 [get_ports {leds[3]}]
set_property PACKAGE_PIN Y18 [get_ports {leds[2]}]
set_property PACKAGE_PIN Y16 [get_ports {leds[1]}]
set_property PACKAGE_PIN V17 [get_ports {leds[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {leds[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]

## PMOD SEG
set_property PACKAGE_PIN P18 [get_ports {seg[7]}]
set_property PACKAGE_PIN R17 [get_ports {seg[6]}]
set_property PACKAGE_PIN R18 [get_ports {seg[5]}]
set_property PACKAGE_PIN U17 [get_ports {seg[4]}]
set_property PACKAGE_PIN W19 [get_ports {seg[3]}]
set_property PACKAGE_PIN Y19 [get_ports {seg[2]}]
set_property PACKAGE_PIN Y17 [get_ports {seg[1]}]
set_property PACKAGE_PIN V18 [get_ports {seg[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

## PMOD LCD
set_property PACKAGE_PIN T10 [get_ports cs]
set_property PACKAGE_PIN T11 [get_ports dc]
set_property PACKAGE_PIN T14 [get_ports sda]
set_property PACKAGE_PIN V12 [get_ports sck]
set_property PACKAGE_PIN W14 [get_ports rst]

set_property IOSTANDARD LVCMOS33 [get_ports cs]
set_property IOSTANDARD LVCMOS33 [get_ports dc]
set_property IOSTANDARD LVCMOS33 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sck]
set_property IOSTANDARD LVCMOS33 [get_ports rst]