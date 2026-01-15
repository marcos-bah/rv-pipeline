# =============================================================================
# Cadence Genus Synthesis Script - RISC-V Pipeline with FPU
# =============================================================================
# Usage: genus -f synthesis/run_synthesis.tcl -log synthesis/logs/genus.log
# Or:    genus -legacy_ui -f synthesis/run_synthesis.tcl
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration Variables - MODIFY THESE FOR YOUR ENVIRONMENT
# -----------------------------------------------------------------------------

# Scenario selection: baseline, ppa1, ppa2
set SCENARIO "baseline"

# Design name
set DESIGN_NAME "topo"

# Paths
set RTL_PATH "../rtl"
set CONSTRAINTS_PATH "."
set OUTPUT_PATH "./output"
set REPORTS_PATH "./reports"

# Library paths - MODIFY THESE FOR YOUR PDK
# Example for typical educational PDK (e.g., FreePDK45, SAED, etc.)
set LIB_PATH "/path/to/your/pdk/lib"
set LIB_NAME "your_library_typical.lib"

# For FreePDK45:
# set LIB_PATH "/tools/FreePDK45/osu_soc/lib/files"
# set LIB_NAME "gscl45nm.lib"

# For SAED32:
# set LIB_PATH "/tools/SAED32_EDK/lib/stdcell_hvt/db_nldm"
# set LIB_NAME "saed32hvt_tt1p05v25c.lib"

# -----------------------------------------------------------------------------
# Parse command line arguments for scenario
# -----------------------------------------------------------------------------
if {[info exists env(SCENARIO)]} {
    set SCENARIO $env(SCENARIO)
}

puts "============================================"
puts "  RISC-V Pipeline Synthesis"
puts "  Scenario: $SCENARIO"
puts "============================================"

# -----------------------------------------------------------------------------
# Create output directories
# -----------------------------------------------------------------------------
file mkdir $OUTPUT_PATH
file mkdir $REPORTS_PATH
file mkdir "${OUTPUT_PATH}/${SCENARIO}"
file mkdir "${REPORTS_PATH}/${SCENARIO}"

# -----------------------------------------------------------------------------
# Set library paths
# -----------------------------------------------------------------------------
# Uncomment and modify for your environment:
# set_db init_lib_search_path $LIB_PATH
# set_db library $LIB_NAME

# For demonstration without actual library:
puts "WARNING: No library specified. Using generic gates."
puts "Modify LIB_PATH and LIB_NAME in this script for your PDK."

# -----------------------------------------------------------------------------
# Read RTL Files
# -----------------------------------------------------------------------------
puts "Reading RTL files..."

# Read all Verilog files
set rtl_files [glob -directory $RTL_PATH *.v]

# Exclude testbench files
set rtl_files_filtered {}
foreach f $rtl_files {
    if {![string match "*_tb.v" $f]} {
        lappend rtl_files_filtered $f
    }
}

puts "RTL files to synthesize:"
foreach f $rtl_files_filtered {
    puts "  $f"
}

read_hdl -sv $rtl_files_filtered

# -----------------------------------------------------------------------------
# Elaborate Design
# -----------------------------------------------------------------------------
puts "Elaborating design..."
elaborate $DESIGN_NAME

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
