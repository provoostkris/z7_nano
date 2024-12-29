# CLOCKS external

  create_clock -period 20.000 [get_ports clk]

# False paths

  set_false_path -from              [get_ports reset_n]
  set_false_path -to                [get_ports rst]