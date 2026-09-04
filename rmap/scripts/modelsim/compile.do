------------------------------------------------------------------------------
--  Compilation execution script
--  rev. 1.0 : 2024 Provoost Kris
------------------------------------------------------------------------------

echo "Remove old files"

  proc detect_lib { lib } { if { [file exists $lib]} { echo " library detected $lib" } }
  proc delete_lib { lib } { if { [file exists $lib]} { file delete -force $lib } }
  proc ensure_lib { lib } { if {![file exists $lib]} { vlib $lib } }

  detect_lib work
  delete_lib work
  ensure_lib work

  set path_rtl   "../.."

echo "Compiling design"

  do vcom_rtl.do

echo "Compiling test bench"

  vcom  -2008 -quiet -work work $path_rtl/bench/tb_RMAP_Decoder_AXI.vhd
  vcom  -2008 -quiet -work work $path_rtl/bench/tb_rmap_to_ahb_bridge.vhd

echo "Compilation script completed "