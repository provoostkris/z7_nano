# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\github\z7_nano\lan\release\vitis\network_system\_ide\scripts\systemdebugger_network_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\github\z7_nano\lan\release\vitis\network_system\_ide\scripts\systemdebugger_network_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-HS2 210241273272" && level==0 && jtag_device_ctx=="jsn-JTAG-HS2-210241273272-23727093-0"}
fpga -file D:/github/z7_nano/lan/release/vitis/network/_ide/bitstream/lan.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw D:/github/z7_nano/lan/release/vitis/lan/export/lan/hw/lan.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source D:/github/z7_nano/lan/release/vitis/network/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow D:/github/z7_nano/lan/release/vitis/network/Debug/network.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
