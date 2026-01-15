# =============================================================================# =============================================================================

# Cadence Genus Synthesis Script - RISC-V Pipeline with FPU# Cadence Genus Synthesis Script - RISC-V Pipeline with FPU

# =============================================================================# =============================================================================

# Usage: genus -f run_synthesis.tcl# Usage: genus -f synthesis/run_synthesis.tcl -log synthesis/logs/genus.log

# =============================================================================# Or:    genus -legacy_ui -f synthesis/run_synthesis.tcl

# =============================================================================

# -----------------------------------------------------------------------------

# Setup Paths# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------# Configuration Variables - MODIFY THESE FOR YOUR ENVIRONMENT

set_db init_lib_search_path ./LIB/# -----------------------------------------------------------------------------

set_db init_hdl_search_path ../rtl/

# Scenario selection: baseline, ppa1, ppa2

# -----------------------------------------------------------------------------set SCENARIO "baseline"

# Read Libraries

# -----------------------------------------------------------------------------# Design name

read_libs slow_vdd1v0_basicCells.libset DESIGN_NAME "topo"



# -----------------------------------------------------------------------------# Paths

# Read RTL Filesset RTL_PATH "../rtl"

# -----------------------------------------------------------------------------set CONSTRAINTS_PATH "."

read_hdl topo.vset OUTPUT_PATH "./output"

read_hdl instruction_fetch.vset REPORTS_PATH "./reports"

read_hdl instruction_decode.v

read_hdl execute_memory.v# Library paths - MODIFY THESE FOR YOUR PDK

read_hdl instruction_memory.v# Example for typical educational PDK (e.g., FreePDK45, SAED, etc.)

read_hdl register_file.vset LIB_PATH "/path/to/your/pdk/lib"

read_hdl alu.vset LIB_NAME "your_library_typical.lib"

read_hdl fpu.v

read_hdl forwarding_unit.v# For FreePDK45:

read_hdl control_unit.v# set LIB_PATH "/tools/FreePDK45/osu_soc/lib/files"

read_hdl main_decoder.v# set LIB_NAME "gscl45nm.lib"

read_hdl ula_decoder.v

read_hdl fpu_decoder.v# For SAED32:

read_hdl sign_extend.v# set LIB_PATH "/tools/SAED32_EDK/lib/stdcell_hvt/db_nldm"

read_hdl pc.v# set LIB_NAME "saed32hvt_tt1p05v25c.lib"

read_hdl adder.v

read_hdl mux_2x1_32bits.v# -----------------------------------------------------------------------------

read_hdl mux_3x1_32bits.v# Parse command line arguments for scenario

read_hdl multiply.v# -----------------------------------------------------------------------------

read_hdl int2fp.vif {[info exists env(SCENARIO)]} {

read_hdl fp2int.v    set SCENARIO $env(SCENARIO)

read_hdl byte_enable_decoder.v}

read_hdl mem_topo_little_endian.v

read_hdl mem_byte_addressable_32wf.vputs "============================================"

read_hdl mem_read_manager.vputs "  RISC-V Pipeline Synthesis"

read_hdl memory_write_first.vputs "  Scenario: $SCENARIO"

puts "============================================"

# -----------------------------------------------------------------------------

# Elaborate Design# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------# Create output directories

elaborate topo# -----------------------------------------------------------------------------

file mkdir $OUTPUT_PATH

# -----------------------------------------------------------------------------file mkdir $REPORTS_PATH

# Read Constraints - Select scenario: baseline (30ns), ppa1 (20ns), ppa2 (10ns)file mkdir "${OUTPUT_PATH}/${SCENARIO}"

# -----------------------------------------------------------------------------file mkdir "${REPORTS_PATH}/${SCENARIO}"

# Baseline: 30ns

read_sdc ./constraints/constraints_baseline.sdc# -----------------------------------------------------------------------------

# Set library paths

# PPA1: 20ns (uncomment to use)# -----------------------------------------------------------------------------

# read_sdc ./constraints/constraints_ppa1.sdc# Uncomment and modify for your environment:

# set_db init_lib_search_path $LIB_PATH

# PPA2: 10ns (uncomment to use)# set_db library $LIB_NAME

# read_sdc ./constraints/constraints_ppa2.sdc

# For demonstration without actual library:

# -----------------------------------------------------------------------------puts "WARNING: No library specified. Using generic gates."

# Synthesisputs "Modify LIB_PATH and LIB_NAME in this script for your PDK."

# -----------------------------------------------------------------------------

set_db syn_generic_effort medium# -----------------------------------------------------------------------------

syn_generic# Read RTL Files

# -----------------------------------------------------------------------------

set_db syn_map_effort mediumputs "Reading RTL files..."

syn_map

# Read all Verilog files

set_db syn_opt_effort mediumset rtl_files [glob -directory $RTL_PATH *.v]

syn_opt

# Exclude testbench files

# -----------------------------------------------------------------------------set rtl_files_filtered {}

# Reportsforeach f $rtl_files {

# -----------------------------------------------------------------------------    if {![string match "*_tb.v" $f]} {

report_timing > ./outputs/topo_timing.rpt        lappend rtl_files_filtered $f

report_area > ./outputs/topo_area.rpt    }

report_power > ./outputs/topo_power.rpt}

report_qor > ./outputs/topo_qor.rpt

report_gates > ./outputs/topo_gates.rptputs "RTL files to synthesize:"

foreach f $rtl_files_filtered {

# -----------------------------------------------------------------------------    puts "  $f"

# Write Outputs}

# -----------------------------------------------------------------------------

write_hdl > ./outputs/topo_netlist.vread_hdl -sv $rtl_files_filtered

write_sdc > ./outputs/topo_constraints.sdc

write_sdf -timescale ns > ./outputs/topo_delays.sdf# -----------------------------------------------------------------------------

# Elaborate Design

puts "============================================"# -----------------------------------------------------------------------------

puts "  Synthesis Complete!"puts "Elaborating design..."

puts "  Outputs saved to ./outputs/"elaborate $DESIGN_NAME

puts "============================================"

# Check for errors
check_design -unresolved

# -----------------------------------------------------------------------------
# Read Constraints
# -----------------------------------------------------------------------------
puts "Reading constraints for scenario: $SCENARIO"

switch $SCENARIO {
    "baseline" {
        read_sdc "${CONSTRAINTS_PATH}/constraints_baseline.sdc"
    }
    "ppa1" {
        read_sdc "${CONSTRAINTS_PATH}/constraints_ppa1.sdc"
    }
    "ppa2" {
        read_sdc "${CONSTRAINTS_PATH}/constraints_ppa2.sdc"
    }
    default {
        puts "ERROR: Unknown scenario $SCENARIO"
        puts "Valid scenarios: baseline, ppa1, ppa2"
        exit 1
    }
}

# -----------------------------------------------------------------------------
# Synthesis
# -----------------------------------------------------------------------------
puts "Starting synthesis..."

# Set synthesis effort
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

# Generic synthesis
syn_generic

# Technology mapping
syn_map

# Optimization
syn_opt

# -----------------------------------------------------------------------------
# Generate Reports
# -----------------------------------------------------------------------------
puts "Generating reports..."

set REPORT_PREFIX "${REPORTS_PATH}/${SCENARIO}/${DESIGN_NAME}"

# Timing report
report_timing > "${REPORT_PREFIX}_timing.rpt"
report_timing -slack_lesser_than 0 > "${REPORT_PREFIX}_timing_violations.rpt"

# Area report
report_area > "${REPORT_PREFIX}_area.rpt"

# Power report
report_power > "${REPORT_PREFIX}_power.rpt"

# Gates report
report_gates > "${REPORT_PREFIX}_gates.rpt"

# QoR (Quality of Results) report
report_qor > "${REPORT_PREFIX}_qor.rpt"

# Design summary
report_summary > "${REPORT_PREFIX}_summary.rpt"

# -----------------------------------------------------------------------------
# Write Output Files
# -----------------------------------------------------------------------------
puts "Writing output files..."

set OUTPUT_PREFIX "${OUTPUT_PATH}/${SCENARIO}/${DESIGN_NAME}"

# Write synthesized netlist
write_hdl > "${OUTPUT_PREFIX}_netlist.v"

# Write SDC constraints
write_sdc > "${OUTPUT_PREFIX}_constraints.sdc"

# Write design database (for Innovus)
# write_design -innovus "${OUTPUT_PREFIX}"

# -----------------------------------------------------------------------------
# Print Summary
# -----------------------------------------------------------------------------
puts ""
puts "============================================"
puts "  Synthesis Complete - $SCENARIO"
puts "============================================"
puts ""
puts "Reports saved to: ${REPORTS_PATH}/${SCENARIO}/"
puts "Outputs saved to: ${OUTPUT_PATH}/${SCENARIO}/"
puts ""

# Print key metrics
puts "Key Metrics:"
puts "------------"
report_qor

puts ""
puts "============================================"
puts "  Check reports for detailed analysis"
puts "============================================"

# Exit (comment out for interactive mode)
# exit
