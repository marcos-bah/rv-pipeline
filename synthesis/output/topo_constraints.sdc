# ####################################################################

#  Created by Genus(TM) Synthesis Solution 22.17-s071_1 on Thu Jan 15 20:13:00 -03 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design topo

create_clock -name "clk" -period 30.0 -waveform {0.0 15.0} [get_ports clk]
set_clock_transition 3.0 [get_clocks clk]
set_false_path -from [get_ports rst]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay 9.0 [get_ports rst]
set_max_fanout 20.000 [current_design]
set_max_transition 4.5 [current_design]
set_input_transition -min 0.3 [get_ports clk]
set_input_transition -max 3.0 [get_ports clk]
set_input_transition -min 0.3 [get_ports rst]
set_input_transition -max 3.0 [get_ports rst]
set_wire_load_mode "enclosed"
set_clock_latency  0.9 [get_clocks clk]
set_clock_latency -source 1.5 [get_clocks clk]
set_clock_uncertainty -setup 3.0 [get_clocks clk]
