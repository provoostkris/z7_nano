
create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
endgroup
create_debug_core u_ila_1 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_1 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_1 ]
endgroup
connect_debug_port u_ila_0/clk [get_nets [list bd_base_i/processing_system7_0/inst/FCLK_CLK0 ]]
connect_debug_port u_ila_1/clk [get_nets [list clk_012 ]]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {AXI_STR_TXD_0_tdata[0]} {AXI_STR_TXD_0_tdata[1]} {AXI_STR_TXD_0_tdata[2]} {AXI_STR_TXD_0_tdata[3]} {AXI_STR_TXD_0_tdata[4]} {AXI_STR_TXD_0_tdata[5]} {AXI_STR_TXD_0_tdata[6]} {AXI_STR_TXD_0_tdata[7]} {AXI_STR_TXD_0_tdata[8]} {AXI_STR_TXD_0_tdata[9]} {AXI_STR_TXD_0_tdata[10]} {AXI_STR_TXD_0_tdata[11]} {AXI_STR_TXD_0_tdata[12]} {AXI_STR_TXD_0_tdata[13]} {AXI_STR_TXD_0_tdata[14]} {AXI_STR_TXD_0_tdata[15]} {AXI_STR_TXD_0_tdata[16]} {AXI_STR_TXD_0_tdata[17]} {AXI_STR_TXD_0_tdata[18]} {AXI_STR_TXD_0_tdata[19]} {AXI_STR_TXD_0_tdata[20]} {AXI_STR_TXD_0_tdata[21]} {AXI_STR_TXD_0_tdata[22]} {AXI_STR_TXD_0_tdata[23]} {AXI_STR_TXD_0_tdata[24]} {AXI_STR_TXD_0_tdata[25]} {AXI_STR_TXD_0_tdata[26]} {AXI_STR_TXD_0_tdata[27]} {AXI_STR_TXD_0_tdata[28]} {AXI_STR_TXD_0_tdata[29]} {AXI_STR_TXD_0_tdata[30]} {AXI_STR_TXD_0_tdata[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {s_tx_dat_tdata[0]} {s_tx_dat_tdata[1]} {s_tx_dat_tdata[2]} {s_tx_dat_tdata[3]} {s_tx_dat_tdata[4]} {s_tx_dat_tdata[5]} {s_tx_dat_tdata[6]} {s_tx_dat_tdata[7]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list AXI_STR_TXD_0_tlast ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list AXI_STR_TXD_0_tready ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list AXI_STR_TXD_0_tvalid ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list s_tx_dat_tlast ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list s_tx_dat_tready ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list s_tx_dat_tvalid ]]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {fifo_tx_data[0]} {fifo_tx_data[1]} {fifo_tx_data[2]} {fifo_tx_data[3]} {fifo_tx_data[4]} {fifo_tx_data[5]} {fifo_tx_data[6]} {fifo_tx_data[7]} ]]
create_debug_port u_ila_1 probe
set_property port_width 8 [get_debug_ports u_ila_1/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {frm_tx_data[0]} {frm_tx_data[1]} {frm_tx_data[2]} {frm_tx_data[3]} {frm_tx_data[4]} {frm_tx_data[5]} {frm_tx_data[6]} {frm_tx_data[7]} ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list fifo_tx_ack_frm ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list fifo_tx_eof ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list fifo_tx_req_frm ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list fifo_tx_sof ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list frm_tx_en ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list frm_tx_err ]]
