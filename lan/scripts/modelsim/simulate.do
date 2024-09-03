------------------------------------------------------------------------------
--  Simulation execution script
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

  do compile.do

echo "start simulation"

  vsim -gui -t ps -L unisim -L unimacro -novopt work.tb_lan

echo "adding waves"

  view wave
  delete wave /*


  add wave                      -group "bench"            -internal    /tb_lan/*

  add wave                      -group "dut"                           /tb_lan/dut/*

  add wave  -expand             -group "i_eth_rx_fifo"                 /tb_lan/dut/i_eth_rx_fifo/*
  add wave  -expand             -group "i_eth_frm_rx"                  /tb_lan/dut/i_eth_frm_rx/*
  add wave  -expand             -group "i_eth_crc32"                   /tb_lan/dut/i_eth_frm_rx/i_eth_crc32/*
  add wave  -expand             -group "i_rgmii_rx_ddr"                /tb_lan/dut/i_rgmii_rx_ddr/*

  add wave  -expand             -group "i_rgmii_tx_fifo"               /tb_lan/dut/i_rgmii_tx_fifo/*
  add wave  -expand             -group "i_rgmii_tx"                    /tb_lan/dut/i_rgmii_tx/*
  add wave  -expand             -group "i_gmii_to_rgmii"               /tb_lan/dut/i_gmii_to_rgmii/*


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