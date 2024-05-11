------------------------------------------------------------------------------
--  Compilation execution script
--  rev. 1.0 : 2024 Provoost Kris
------------------------------------------------------------------------------

# Clearing the transcript window:
.main clear

echo "Remove old files"

  proc detect_lib { lib } { if { [file exists $lib]} { echo " library detected $lib" } }
  proc delete_lib { lib } { if { [file exists $lib]} { file delete -force $lib } }
  proc ensure_lib { lib } { if {![file exists $lib]} { vlib $lib } }

  detect_lib work
  delete_lib work
  ensure_lib work

  set path_rtl   "../.."

  # run this command in the vivado tool to generate the libraries
  #
  #compile_simlib \
  #  -simulator modelsim \
  #  -simulator_exec_path {C:/modeltech64_10.5/win64} \
  #  -family zynq \
  #  -language vhdl \
  #  -library unisim \
  #  -dir {compile_simlib} \
  #  -no_ip_compile \
  #  -verbose

echo "Mapping primitives for Xilinx"

echo "Compiling design"

  do vcom_rtl.do

echo "Compiling test bench"

  vcom  -2008 -quiet -work work $path_rtl/bench/tb_hdmi_tx.vhd

echo "Compilation script completed "