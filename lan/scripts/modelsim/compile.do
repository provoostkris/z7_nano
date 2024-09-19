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

  detect_lib nw_adapt
  delete_lib nw_adapt
  ensure_lib nw_adapt

  detect_lib nw_util
  delete_lib nw_util
  ensure_lib nw_util

  detect_lib nw_ethernet
  delete_lib nw_ethernet
  ensure_lib nw_ethernet

echo "Mapping primitives for Xilinx"

  vmap unisim   vivado_simlib/unisim
  vmap unimacro vivado_simlib/unimacro

echo "Compiling netwiz required files"

    #define where the netwiz repo is located
    set path_netwiz   "../../../../"

    vcom  -2008 -quiet -work nw_adapt     $path_netwiz/netwiz/nw_adapt/src/nw_adaptations_pkg.vhd

    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_types_pkg.vhd
    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_util_pkg.vhd
    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_crc_pkg.vhd
    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_nrs_pkg.vhd
    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_prbs_pkg.vhd
    vcom  -2008 -quiet -work nw_util      $path_netwiz/netwiz/nw_util/src/nw_util_context.vhd

    vcom  -2008 -quiet -work nw_ethernet  $path_netwiz/netwiz/nw_ethernet/src/nw_ethernet_pkg.vhd

echo "Compiling design"

  echo " make sure to run the vivado project once before the simulation , or the sim folder will be empty"

  set path_bd "../../bd_base/prj_bd_base.gen/sources_1/bd/bd_base/ip"

  set handle 0
  if {$handle == 0 } { 
  }
  if {$handle == 1 } { 
    vlog  -work work $path_bd/bd_base_auto_pc_0/bd_base_auto_pc_0_sim_netlist.v
    vlog  -work work $path_bd/bd_base_axi_fifo_mm_s_0_0/bd_base_axi_fifo_mm_s_0_0_sim_netlist.v
    vlog  -work work $path_bd/bd_base_processing_system7_0_0/bd_base_processing_system7_0_0_sim_netlist.v
    vlog  -work work $path_bd/bd_base_rst_ps7_0_50M_0/bd_base_rst_ps7_0_50M_0_sim_netlist.v
  }
  if {$handle == 2 } { 
    vcom -2008 -work work $path_bd/bd_base_auto_pc_0/bd_base_auto_pc_0_sim_netlist.vhdl
    vcom -2008 -work work $path_bd/bd_base_axi_fifo_mm_s_0_0/bd_base_axi_fifo_mm_s_0_0_sim_netlist.vhdl
    vcom -2008 -work work $path_bd/bd_base_processing_system7_0_0/bd_base_processing_system7_0_0_sim_netlist.vhdl
    vcom -2008 -work work $path_bd/bd_base_rst_ps7_0_50M_0/bd_base_rst_ps7_0_50M_0_sim_netlist.vhdl
  }
  
  set path_bd "../../bd_base/prj_bd_base.gen/sources_1/bd/bd_base/sim"

    vcom -2008 -work work $path_bd/bd_base.vhd

  set path_rtl   "../.."
  do vcom_rtl.do


echo "Compiling test bench"

  vcom  -2008 -quiet -work work $path_rtl/bench/tb_lan.vhd

echo "Compilation script completed "