# CLOCKS external

  create_clock -period 20.000 [get_ports clk]
  create_clock -period  8.000 [get_ports rgmii_rxc]
  create_generated_clock -name rgmii_txc -source [get_pins {i_rgmii_tx_ddr/i_rgmii_txc/C}] -divide_by 1 [get_ports {rgmii_txc}]


# False paths

  set_false_path -to                [get_ports pll_lock]
  set_false_path -from              [get_ports {key_tri_i[0]}]
  set_false_path -to                [get_ports {led_tri_o[0]}]



# Definitions and groups

  set rgmii_td      [get_ports {rgmii_td[*]}]
  set rgmii_tx_ctl  [get_ports rgmii_tx_ctl]

  set rgmii_rd      [get_ports {rgmii_rd[*]}]
  set rgmii_rx_ctl  [get_ports rgmii_rx_ctl]

# External PHY Parameter (Refer to MarvelPHY 88EE1111)
# TX
  set tsu      -0.9
  set th        2.7
# RX
  set tco_max   0.8
  set tco_min  -0.8

# Note the schematic is designed such that the ETH TRCVR is
# adding the 2ns delay, so that the FPGA must not delay the clocks
# mind we have to constrain both edges since it is a DDR interface

  set_output_delay -clock [get_clocks {rgmii_txc}] -max $tsu $rgmii_td -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -max $tsu $rgmii_td -clock_fall -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min $th  $rgmii_td -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min $th  $rgmii_td -clock_fall -add_delay
  
  set_output_delay -clock [get_clocks {rgmii_txc}] -max $tsu $rgmii_tx_ctl -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -max $tsu $rgmii_tx_ctl -clock_fall -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min $th  $rgmii_tx_ctl -add_delay
  set_output_delay -clock [get_clocks {rgmii_txc}] -min $th  $rgmii_tx_ctl -clock_fall -add_delay
