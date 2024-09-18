# Typical usage: vivado -mode tcl -source build.tcl

set loc_script [file normalize [info script]]
set loc_folder [file dirname $loc_script]
puts $loc_folder
cd $loc_folder

set CompilationStart [clock seconds]

# Clean workspace
file delete -force ../../release/vivado

# Create the project and directory structure
create_project -force lan ../../release/vivado -part xc7z020clg400-2

set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

#
# Add various sources to the project
  set fp [open ../../rtl.txt]
  while {-1 != [gets $fp line]} {
      set file_src ../../$line
      puts $file_src
      add_files -norecurse $file_src
  }

  read_bd                         ../../bd_base/prj_bd_base.srcs/sources_1/bd/bd_base/bd_base.bd
  # uncomment in case the wrapper is needed
  #make_wrapper -files [get_files  ../../bd_base/prj_bd_base.srcs/sources_1/bd/bd_base/bd_base.bd] -top
  #add_files                       ../../bd_base/prj_bd_base.gen/sources_1/bd/bd_base/hdl/bd_base_wrapper.vhd

#
# Add various constraints to the project
add_files ../../constraints/pin_constraints.xdc
add_files ../../constraints/timings.xdc

#
# Update to set top and file compile order
update_compile_order -fileset sources_1

#
# Launch Synthesis
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1
# source add_debug.tcl

#
# Launch Implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1


#
# Export for Vitis development
write_hw_platform -fixed -include_bit -force -file lan.xsa


set duration [expr [clock seconds]-$CompilationStart]
set LastCompilationTime $CompilationStart
puts [format "Compilation duration: %d:%02d" [expr $duration/60] [expr $duration%60]]
puts [clock format $LastCompilationTime -format {Reporting last compilation time: %A, %d of %B, %Y - %H:%M:%S}]