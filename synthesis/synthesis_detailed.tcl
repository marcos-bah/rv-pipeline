# =============================================================================
# Cadence Genus Synthesis Script - Detailed Analysis
# RISC-V Pipeline with FPU
# =============================================================================
# This script provides detailed metrics collection for PPA analysis
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration - Modify for your environment
# -----------------------------------------------------------------------------
set DESIGN_NAME "topo"
set SCENARIO [expr {[info exists env(SCENARIO)] ? $env(SCENARIO) : "baseline"}]

# Paths
set RTL_PATH "../rtl"
set CONSTRAINTS_PATH "."
set OUTPUT_PATH "./output/${SCENARIO}"
set REPORTS_PATH "./reports/${SCENARIO}"

# Create directories
file mkdir $OUTPUT_PATH
file mkdir $REPORTS_PATH

# -----------------------------------------------------------------------------
# Library Setup - MODIFY FOR YOUR PDK
# -----------------------------------------------------------------------------
# Example configurations for common PDKs:

# FreePDK45:
# set_db init_lib_search_path "/tools/FreePDK45/osu_soc/lib/files"
# set_db library "gscl45nm.lib"

# SAED32 (Educational):
# set_db init_lib_search_path "/tools/SAED32_EDK/lib/stdcell_hvt/db_nldm"
# set_db library "saed32hvt_tt1p05v25c.lib"

# NanGate45 (Open):
# set_db init_lib_search_path "/tools/NanGate45/lib"
# set_db library "NangateOpenCellLibrary_typical.lib"

# TSMC 28nm (if available):
# set_db init_lib_search_path "/tools/tsmc28/lib"
# set_db library "tcbn28hpcplusbwp7t30p140tt0p9v25c.lib"

puts "============================================"
puts "  Scenario: $SCENARIO"
puts "============================================"

# -----------------------------------------------------------------------------
# Read Design
# -----------------------------------------------------------------------------
set rtl_files [list \
    "${RTL_PATH}/topo.v" \
    "${RTL_PATH}/instruction_fetch.v" \
    "${RTL_PATH}/instruction_decode.v" \
    "${RTL_PATH}/execute_memory.v" \
    "${RTL_PATH}/instruction_memory.v" \
    "${RTL_PATH}/register_file.v" \
    "${RTL_PATH}/alu.v" \
    "${RTL_PATH}/fpu.v" \
    "${RTL_PATH}/forwarding_unit.v" \
    "${RTL_PATH}/control_unit.v" \
    "${RTL_PATH}/main_decoder.v" \
    "${RTL_PATH}/ula_decoder.v" \
    "${RTL_PATH}/fpu_decoder.v" \
    "${RTL_PATH}/sign_extend.v" \
    "${RTL_PATH}/pc.v" \
    "${RTL_PATH}/adder.v" \
    "${RTL_PATH}/mux_2x1_32bits.v" \
    "${RTL_PATH}/mux_3x1_32bits.v" \
    "${RTL_PATH}/multiply.v" \
    "${RTL_PATH}/int2fp.v" \
    "${RTL_PATH}/fp2int.v" \
    "${RTL_PATH}/byte_enable_decoder.v" \
    "${RTL_PATH}/mem_topo_little_endian.v" \
    "${RTL_PATH}/mem_byte_addressable_32wf.v" \
    "${RTL_PATH}/mem_read_manager.v" \
    "${RTL_PATH}/memory_write_first.v" \
]

read_hdl -sv $rtl_files
elaborate $DESIGN_NAME
check_design -unresolved

# -----------------------------------------------------------------------------
# Read Constraints
# -----------------------------------------------------------------------------
read_sdc "${CONSTRAINTS_PATH}/constraints_${SCENARIO}.sdc"

# -----------------------------------------------------------------------------
# Synthesis with Different Effort Levels
# -----------------------------------------------------------------------------
puts "Synthesizing with high effort..."

set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

# Enable advanced optimizations
set_db hdl_track_filename_row_col true
set_db optimize_constant_0_flops true
set_db optimize_constant_1_flops true

syn_generic
syn_map
syn_opt

# Additional optimization passes
puts "Running incremental optimization..."
syn_opt -incr

# -----------------------------------------------------------------------------
# Detailed Reports
# -----------------------------------------------------------------------------
puts "Generating detailed reports..."

# Timing Reports
report_timing -max_paths 10 > "${REPORTS_PATH}/timing_summary.rpt"
report_timing -slack_lesser_than 0 -max_paths 50 > "${REPORTS_PATH}/timing_violations.rpt"
report_timing -from [all_registers] -to [all_registers] -max_paths 10 > "${REPORTS_PATH}/timing_reg2reg.rpt"

# Area Reports
report_area -detail > "${REPORTS_PATH}/area_detail.rpt"
report_area -hierarchy > "${REPORTS_PATH}/area_hierarchy.rpt"

# Power Reports
report_power -detail > "${REPORTS_PATH}/power_detail.rpt"
report_power -hierarchy > "${REPORTS_PATH}/power_hierarchy.rpt"

# Cell Reports
report_gates > "${REPORTS_PATH}/gates.rpt"
report_gates -power > "${REPORTS_PATH}/gates_power.rpt"

# QoR Report
report_qor > "${REPORTS_PATH}/qor.rpt"

# Clock Report
report_clocks > "${REPORTS_PATH}/clocks.rpt"

# Design Statistics
report_summary > "${REPORTS_PATH}/summary.rpt"

# -----------------------------------------------------------------------------
# Extract Key Metrics to CSV
# -----------------------------------------------------------------------------
puts "Extracting metrics..."

# Get timing info
set wns [get_db timing_analysis_worst_negative_slack_value]
set tns [get_db timing_analysis_total_negative_slack_value]

# Get area info
set total_area [get_db [get_db current_design] .area]

# Get power info
set total_power [get_db [get_db current_design] .power]

# Count cells
set num_cells [llength [get_db insts]]
set num_regs [llength [get_db insts -if {.is_sequential}]]

# Write metrics to file
set metrics_file [open "${REPORTS_PATH}/metrics.csv" w]
puts $metrics_file "Metric,Value"
puts $metrics_file "Scenario,$SCENARIO"
puts $metrics_file "WNS (ns),$wns"
puts $metrics_file "TNS (ns),$tns"
puts $metrics_file "Total Area (um2),$total_area"
puts $metrics_file "Total Power (mW),$total_power"
puts $metrics_file "Total Cells,$num_cells"
puts $metrics_file "Sequential Cells,$num_regs"
close $metrics_file

puts ""
puts "============================================"
puts "  Metrics Summary - $SCENARIO"
puts "============================================"
puts "  WNS:          $wns ns"
puts "  TNS:          $tns ns"
puts "  Total Area:   $total_area um2"
puts "  Total Power:  $total_power mW"
puts "  Total Cells:  $num_cells"
puts "  Registers:    $num_regs"
puts "============================================"

# -----------------------------------------------------------------------------
# Write Outputs
# -----------------------------------------------------------------------------
write_hdl > "${OUTPUT_PATH}/netlist.v"
write_sdc > "${OUTPUT_PATH}/constraints.sdc"

puts ""
puts "Synthesis complete for scenario: $SCENARIO"
puts "Reports: ${REPORTS_PATH}/"
puts "Outputs: ${OUTPUT_PATH}/"
