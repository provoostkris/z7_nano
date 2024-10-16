# CLOCKS external

  create_clock -period 20.000 [get_ports clk]
  create_clock -period  8.000 [get_ports rgmii_rxc]
  create_generated_clock -name rgmii_txc -source [get_pins {i_rgmii_tx_ddr/i_rgmii_txc/C}] -divide_by 1 [get_ports {rgmii_txc}]

# False paths

  set_false_path -to                [get_ports led]
  set_false_path -to                [get_ports pll_lock]
  
  #set_false_path -to                [get_pins -hier *shift_reg*/D]
  set_false_path -to                [get_pins -hier *_sync1_reg*/D]
  set_false_path -to                [get_pins -hier *s_rst_sync2_reg*/D]


# Definitions and groups

  set rgmii_td      [get_ports {rgmii_td[*]}]
  set rgmii_tx_ctl  [get_ports rgmii_tx_ctl]

  set rgmii_rd      [get_ports {rgmii_rd[*]}]
  set rgmii_rx_ctl  [get_ports rgmii_rx_ctl]

# External PHY Parameter
# TX
  set tsu       1.2
  set th        1.2
  set tx_del    2.0
# RX
  set tco_max   1.0
  set tco_min   1.0
  set rx_del    2.0

# Note the schematic is designed such that the ETH TRCVR is
# adding the 2ns delay, so that the FPGA must not delay the clocks
# mind we have to constrain both edges since it is a DDR interface

  set_output_delay -clock [get_clocks {rgmii_txc}] -max [expr $tsu + $tx_del]     $rgmii_td      -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -max [expr $tsu + $tx_del]     $rgmii_td      -clock_fall -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min [expr $tx_del - $th ]     $rgmii_td      -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min [expr $tx_del - $th ]     $rgmii_td      -clock_fall -add_delay
                                                                 
  set_output_delay -clock [get_clocks {rgmii_txc}] -max [expr $tsu + $tx_del]     $rgmii_tx_ctl  -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -max [expr $tsu + $tx_del]     $rgmii_tx_ctl  -clock_fall -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min [expr $tx_del - $th ]     $rgmii_tx_ctl  -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min [expr $tx_del - $th ]     $rgmii_tx_ctl  -clock_fall -add_delay

  set_input_delay -clock  [get_clocks {rgmii_rxc}] -max [expr $tco_max - $rx_del] $rgmii_rd      -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -max [expr $tco_max - $rx_del] $rgmii_rd      -clock_fall -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -min [expr $tco_min - $rx_del] $rgmii_rd      -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -min [expr $tco_min - $rx_del] $rgmii_rd      -clock_fall -add_delay

  set_input_delay -clock  [get_clocks {rgmii_rxc}] -max [expr $tco_max - $rx_del] $rgmii_rx_ctl  -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -max [expr $tco_max - $rx_del] $rgmii_rx_ctl  -clock_fall -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -min [expr $tco_min - $rx_del] $rgmii_rx_ctl  -add_delay
  set_input_delay -clock  [get_clocks {rgmii_rxc}] -min [expr $tco_min - $rx_del] $rgmii_rx_ctl  -clock_fall -add_delay