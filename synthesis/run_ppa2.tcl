# =============================================================================
# Cadence Genus Synthesis Script - RISC-V Pipeline (PPA2)
# =============================================================================
# Usage: genus -f run_ppa2.tcl
# Target: 10ns clock (100 MHz) - Aggressive timing optimization
# =============================================================================

puts "============================================"
puts "  RISC-V Pipeline Synthesis - PPA2"
puts "  Target Clock: 10ns (100 MHz)"
puts "============================================"

# =============================================================================
# 1. CONFIGURATION
# =============================================================================

set DESIGN_NAME    "topo"
set SCENARIO       "ppa2"
set LIB_PATH       "./LIB"
set RTL_PATH       "../rtl"
set CONSTRAINTS    "./constraints/constraints_ppa2.sdc"
set OUTPUT_DIR     "./output/${SCENARIO}"
set REPORTS_DIR    "./reports/${SCENARIO}"

# =============================================================================
# 2. SETUP
# =============================================================================

# Create output directories
file mkdir $OUTPUT_DIR
file mkdir $REPORTS_DIR

# Set library search path
set_db init_lib_search_path $LIB_PATH
set_db init_hdl_search_path $RTL_PATH

# Read standard cell library
read_libs slow_vdd1v0_basicCells.lib

# =============================================================================
# 3. READ RTL
# =============================================================================

puts "Reading RTL files..."

# Define SYNTHESIS macro for conditional compilation
set_db hdl_verilog_defines "SYNTHESIS"

# Top module
read_hdl topo.v

# Pipeline stages
read_hdl instruction_fetch.v
read_hdl instruction_decode.v
read_hdl execute_memory.v

# Memories
read_hdl instruction_memory.v
read_hdl data_memory.v
read_hdl mem_topo_little_endian.v
read_hdl mem_byte_addressable_32wf.v
read_hdl mem_read_manager.v
read_hdl memory_write_first.v

# Datapath components
read_hdl register_file.v
read_hdl alu.v
read_hdl fpu.v
read_hdl pc.v
read_hdl adder.v
read_hdl multiply.v
read_hdl int2fp.v
read_hdl fp2int.v

# Control
read_hdl control_unit.v
read_hdl main_decoder.v
read_hdl ula_decoder.v
read_hdl fpu_decoder.v
read_hdl forwarding_unit.v
read_hdl sign_extend.v
read_hdl byte_enable_decoder.v

# Multiplexers
read_hdl mux_2x1_32bits.v
read_hdl mux_3x1_32bits.v

# =============================================================================
# 4. ELABORATE
# =============================================================================

puts "Elaborating design..."
elaborate $DESIGN_NAME

# Verify design
check_design -unresolved

# =============================================================================
# 5. CONSTRAINTS
# =============================================================================

puts "Reading constraints (10ns clock - PPA2)..."
read_sdc $CONSTRAINTS

# =============================================================================
# 6. SYNTHESIS
# =============================================================================

puts "Running synthesis (express effort - maximum performance)..."

# Generic synthesis - express effort for aggressive timing
set_db syn_generic_effort express
syn_generic

# Technology mapping - express effort
set_db syn_map_effort express
syn_map

# Optimization - express effort for maximum performance
set_db syn_opt_effort express
syn_opt

# Additional timing optimization pass
puts "Running incremental optimization..."
syn_opt -incr

# =============================================================================
# 7. REPORTS
# =============================================================================

puts "Generating reports..."

report_timing  > "${REPORTS_DIR}/${DESIGN_NAME}_${SCENARIO}_timing.rpt"
report_area    > "${REPORTS_DIR}/${DESIGN_NAME}_${SCENARIO}_area.rpt"
report_power   > "${REPORTS_DIR}/${DESIGN_NAME}_${SCENARIO}_power.rpt"
report_gates   > "${REPORTS_DIR}/${DESIGN_NAME}_${SCENARIO}_gates.rpt"
report_qor     > "${REPORTS_DIR}/${DESIGN_NAME}_${SCENARIO}_qor.rpt"

# =============================================================================
# 8. OUTPUT
# =============================================================================

puts "Writing output files..."

write_hdl > "${OUTPUT_DIR}/${DESIGN_NAME}_${SCENARIO}_netlist.v"
write_sdc > "${OUTPUT_DIR}/${DESIGN_NAME}_${SCENARIO}_constraints.sdc"
write_sdf -timescale ns > "${OUTPUT_DIR}/${DESIGN_NAME}_${SCENARIO}_delays.sdf"

# =============================================================================
# 9. SUMMARY
# =============================================================================

puts ""
puts "============================================"
puts "  PPA2 Synthesis Complete!"
puts "============================================"
puts "  Scenario:    ${SCENARIO}"
puts "  Clock:       10ns (100 MHz)"
puts "  Reports:     ${REPORTS_DIR}/"
puts "  Outputs:     ${OUTPUT_DIR}/"
puts "============================================"

exit
