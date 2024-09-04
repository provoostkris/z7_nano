create_clock -period 20.000 [get_ports clk]
create_clock -period  8.000 [get_ports rgmii_rxc]


set_false_path -to                [get_ports pll_lock]


create_clock -period 8.000 -name VIRTUAL_clk_eth -waveform {0.000 4.000}
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -clock_fall -min -add_delay 0.000 [get_ports {rgmii_td[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -clock_fall -max -add_delay 2.000 [get_ports {rgmii_td[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -min -add_delay 0.000 [get_ports {rgmii_td[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -max -add_delay 2.000 [get_ports {rgmii_td[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -clock_fall -min -add_delay 0.000 [get_ports rgmii_tx_ctl]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -clock_fall -max -add_delay 2.000 [get_ports rgmii_tx_ctl]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -min -add_delay 0.000 [get_ports rgmii_tx_ctl]
set_output_delay -clock [get_clocks VIRTUAL_clk_eth] -max -add_delay 2.000 [get_ports rgmii_tx_ctl]