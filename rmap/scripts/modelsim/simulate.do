------------------------------------------------------------------------------
--  Simulation execution script
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

  do compile.do

echo "start simulation"

  set bench "tb_RMAP_Decoder_AXI"
  -- set bench "tb_rmap_to_ahb_bridge"

  vsim -gui -t ns -novopt work.$bench

echo "adding waves"

  view wave
  delete wave /*

  add wave  -expand             -group "bench"                         /$bench/*

  add wave                      -group "dut"                           /$bench/dut/*

  vcd file rmap.vcd
  vcd add -r /$bench/*
  vcd on


echo "view wave forms"

  set NumericStdNoWarnings 1
  set StdArithNoWarnings 1
  run 1 ns
  set NumericStdNoWarnings 0
  set StdArithNoWarnings 0

  run -all
  vcd flush
  vcd off


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
  configure wave -timelineunits us
  update

  wave zoom full