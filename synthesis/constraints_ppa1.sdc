# =============================================================================
# SDC Constraints - PPA1 Scenario (20ns)
# RISC-V Pipeline with FPU
# =============================================================================

# -----------------------------------------------------------------------------
# Clock Definition
# -----------------------------------------------------------------------------
set CLK_PERIOD 20.0
set CLK_NAME clk

# Create clock
create_clock -name $CLK_NAME -period $CLK_PERIOD [get_ports clk]

# -----------------------------------------------------------------------------
# Clock Uncertainty and Transition (from Table 1)
# -----------------------------------------------------------------------------
# Setup uncertainty: 10% of clock period
set CLK_UNCERTAINTY [expr $CLK_PERIOD * 0.10]
set_clock_uncertainty -setup $CLK_UNCERTAINTY [get_clocks $CLK_NAME]

# Clock transition: 10% of clock period
set CLK_TRANSITION [expr $CLK_PERIOD * 0.10]
set_clock_transition $CLK_TRANSITION [get_clocks $CLK_NAME]

# -----------------------------------------------------------------------------
# Clock Latency (from Table 1)
# -----------------------------------------------------------------------------
# Source latency: 5% of clock period
set CLK_SOURCE_LATENCY [expr $CLK_PERIOD * 0.05]
set_clock_latency -source $CLK_SOURCE_LATENCY [get_clocks $CLK_NAME]

# Network latency: 3% of clock period
set CLK_NETWORK_LATENCY [expr $CLK_PERIOD * 0.03]
set_clock_latency $CLK_NETWORK_LATENCY [get_clocks $CLK_NAME]

# -----------------------------------------------------------------------------
# Input/Output Delays (from Table 1)
# -----------------------------------------------------------------------------
# Input delay: 30% of clock period
set INPUT_DELAY [expr $CLK_PERIOD * 0.30]
set_input_delay -clock $CLK_NAME $INPUT_DELAY [all_inputs]

# Remove input delay from clock port
set_input_delay -clock $CLK_NAME 0 [get_ports clk]

# Output delay: 30% of clock period
set OUTPUT_DELAY [expr $CLK_PERIOD * 0.30]
set_output_delay -clock $CLK_NAME $OUTPUT_DELAY [all_outputs]

# -----------------------------------------------------------------------------
# Load and Transition Constraints (from Table 1)
# -----------------------------------------------------------------------------
# Output load: 0.04pF
set_load 0.04 [all_outputs]

# Input transition: min 1%, max 10% of clock period
set INPUT_MIN_TRANS [expr $CLK_PERIOD * 0.01]
set INPUT_MAX_TRANS [expr $CLK_PERIOD * 0.10]
set_input_transition -min $INPUT_MIN_TRANS [all_inputs]
set_input_transition -max $INPUT_MAX_TRANS [all_inputs]

# -----------------------------------------------------------------------------
# Design Rule Constraints
# -----------------------------------------------------------------------------
# Set max transition for all nets
set_max_transition [expr $CLK_PERIOD * 0.15] [current_design]

# Set max fanout
set_max_fanout 20 [current_design]

# -----------------------------------------------------------------------------
# False Paths
# -----------------------------------------------------------------------------
# Reset is asynchronous - set as false path for timing
set_false_path -from [get_ports rst]

# -----------------------------------------------------------------------------
# Report Clock Info
# -----------------------------------------------------------------------------
puts "============================================"
puts "PPA1 Constraints Summary:"
puts "  Clock Period:       ${CLK_PERIOD} ns"
puts "  Clock Uncertainty:  ${CLK_UNCERTAINTY} ns (10%)"
puts "  Clock Transition:   ${CLK_TRANSITION} ns (10%)"
puts "  Source Latency:     ${CLK_SOURCE_LATENCY} ns (5%)"
puts "  Network Latency:    ${CLK_NETWORK_LATENCY} ns (3%)"
puts "  Input Delay:        ${INPUT_DELAY} ns (30%)"
puts "  Output Delay:       ${OUTPUT_DELAY} ns (30%)"
puts "  Output Load:        0.04 pF"
puts "  Input Min Trans:    ${INPUT_MIN_TRANS} ns (1%)"
puts "  Input Max Trans:    ${INPUT_MAX_TRANS} ns (10%)"
puts "============================================"
