------------------------------------------------------------------------------
--  Simulation execution script
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

  do compile.do

echo "start simulation"

  vsim -gui -t ns -novopt work.tb_pmod_top

echo "adding waves"

  view wave
  delete wave /*

  add wave  -expand             -group "bench"                         /tb_pmod_top/*

  add wave                      -group "dut"                           /tb_pmod_top/dut/*
  add wave                      -group "led"                           /tb_pmod_top/dut/i_pmod_led/*
  add wave                      -group "seg"                           /tb_pmod_top/dut/i_pmod_seg/*
  add wave                      -group "lcd"                           /tb_pmod_top/dut/i_pmod_lcd/*


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
  configure wave -signalnamewidth 2
  configure wave -snapdistance 10
  configure wave -datasetprefix 0
  configure wave -rowmargin 4
  configure wave -childrowmargin 2
  configure wave -gridoffset 0
  configure wave -gridperiod 1
  configure wave -griddelta 40
  configure wave -timeline 1
  configure wave -timelineunits us
  update

  wave zoom full