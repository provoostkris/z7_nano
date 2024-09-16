# Typical usage: vivado -mode tcl -source build.tcl

set loc_script [file normalize [info script]]
set loc_folder [file dirname $loc_script]
puts $loc_folder
cd $loc_folder

set CompilationStart [clock seconds]

# Create the project and directory structure
create_project -force gen_sim_libs ./output -part xc7z020clg400-2

set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

#
# generate simulation libraries
#

  compile_simlib \
   -simulator modelsim \
   -simulator_exec_path {C:/modeltech64_10.5/win64} \
   -family zynq \
   -language vhdl \
   -library unisim \
   -library xpm \
   -dir {../modelsim/vivado_simlib} \
   -no_ip_compile \
   -verbose


set duration [expr [clock seconds]-$CompilationStart]
set LastCompilationTime $CompilationStart
puts [format "Compilation duration: %d:%02d" [expr $duration/60] [expr $duration%60]]
puts [clock format $LastCompilationTime -format {Reporting last compilation time: %A, %d of %B, %Y - %H:%M:%S}]