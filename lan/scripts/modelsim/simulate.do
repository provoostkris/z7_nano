------------------------------------------------------------------------------
--  Simulation execution script
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

  do compile.do

echo "start simulation"

  set c_speed 100

  vsim -gui -t ps \
    -g g_speed=$c_speed \
    -L unisim \
    -L unimacro \
    -novopt \
    work.tb_lan

echo "adding waves"

  view wave
  delete wave /*

  add wave    -group "dut"                           /tb_lan/dut/*
  add wave    -group "rgmii_rx_model"                /tb_lan/rgmii_rx_model/*
  add wave    -group "rgmii_tx_model"                /tb_lan/rgmii_tx_model/*

  add wave    -divider "RX"
  add wave    -group "i_axis_width_converter_rx"     /tb_lan/dut/i_axis_width_converter_rx/*
  add wave    -group "i_eth_frm_rx"                  /tb_lan/dut/i_eth_frm_rx/*
  --add wave    -group "i_rgmii_rx_sdr"                /tb_lan/dut/gen_slow_rx/i_rgmii_rx_sdr/*
  --add wave    -group "i_rgmii_rx_ddr"                /tb_lan/dut/gen_fast_rx/i_rgmii_rx_ddr/*
  if {$c_speed == 100} {
    add wave    -group "i_rgmii_rx_sdr"                /tb_lan/dut/gen_slow_rx/i_rgmii_rx_sdr/*
  }
  if {$c_speed == 1000} {
    add wave    -group "i_rgmii_rx_ddr"                /tb_lan/dut/gen_fast_rx/i_rgmii_rx_ddr/*
  }
  add wave    -divider "TX"
  add wave    -group "i_axis_width_converter_tx"     /tb_lan/dut/i_axis_async_fifo_adapter_tx/*
  add wave    -group "i_eth_frm_tx"                  /tb_lan/dut/i_eth_frm_tx/*
  add wave    -group "i_rgmii_tx_ddr"                /tb_lan/dut/i_rgmii_tx_ddr/*

  add wave    -divider "APB slaves"
  add wave    -group "slave 1    "           -ports    /tb_lan/dut/i_apb3_slave_1/*
  add wave    -group "slave 2    "           -ports    /tb_lan/dut/i_apb3_slave_2/*
  add wave    -group "slave 3    "           -ports    /tb_lan/dut/i_apb3_slave_3/*
  add wave    -group "slave 4    "           -ports    /tb_lan/dut/i_apb3_slave_4/*

  add wave    -divider "BD"
  --add wave    -group "bd_base_i"           -ports    /tb_lan/dut/bd_base_i/*

echo "view wave forms"

  set NumericStdNoWarnings 1
  set StdArithNoWarnings 1
  run 1 ns
  set NumericStdNoWarnings 0
  set StdArithNoWarnings 0

  run -all

  configure wave -namecolwidth  370
  configure wave -valuecolwidth 180
  configure wave -justifyvalue right
  configure wave -signalnamewidth 1
  configure wave -snapdistance 10
  configure wave -datasetprefix 0
  configure wave -rowmargin 4
  configure wave -childrowmargin 2
  configure wave -gridoffset 0
  configure wave -gridperiod 1
  configure wave -griddelta 40
  configure wave -timeline 1
  configure wave -timelineunits ns
  update

  wave zoom full