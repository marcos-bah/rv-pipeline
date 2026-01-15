#!/bin/bash
# =============================================================================
# Run All Synthesis Scenarios
# RISC-V Pipeline with FPU
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  RISC-V Pipeline Synthesis - All Scenarios"
echo "============================================"
echo ""

# Create directories
mkdir -p logs output reports

# Function to run synthesis for a scenario
run_scenario() {
    local scenario=$1
    local period=$2
    
    echo ""
    echo "============================================"
    echo "  Running Scenario: $scenario (${period}ns)"
    echo "============================================"
    
    # Export scenario for TCL script
    export SCENARIO=$scenario
    
    # Run Genus
    # Option 1: Legacy UI (older Genus versions)
    # genus -legacy_ui -f run_synthesis.tcl -log logs/genus_${scenario}.log
    
    # Option 2: Modern Genus
    genus -f run_synthesis.tcl -log logs/genus_${scenario}.log 2>&1 | tee logs/genus_${scenario}_console.log
    
    if [ $? -eq 0 ]; then
        echo "[PASS] Scenario $scenario completed successfully"
    else
        echo "[FAIL] Scenario $scenario failed"
    fi
}

# Run all three scenarios
run_scenario "baseline" "30"
run_scenario "ppa1" "20"
run_scenario "ppa2" "10"

echo ""
echo "============================================"
echo "  All Scenarios Complete"
echo "============================================"
echo ""
echo "Reports location:"
echo "  - Baseline (30ns): reports/baseline/"
echo "  - PPA1 (20ns):     reports/ppa1/"
echo "  - PPA2 (10ns):     reports/ppa2/"
echo ""

# Generate comparison summary
echo "Generating comparison summary..."

cat > reports/comparison_summary.txt << 'EOF'
=============================================================================
RISC-V Pipeline Synthesis - Comparison Summary
=============================================================================

Scenario     | Clock Period | Expected Trade-offs
-------------|--------------|--------------------
Baseline     | 30 ns        | Lowest area/power, positive slack
PPA1         | 20 ns        | Medium area/power, tighter timing
PPA2         | 10 ns        | Highest area/power, possible violations

=============================================================================
Metrics to Compare:
=============================================================================

1. TIMING:
   - Worst Negative Slack (WNS)
   - Total Negative Slack (TNS)
   - Number of violating paths
   - Critical path delay

2. AREA:
   - Total cell area
   - Combinational area
   - Sequential area (flip-flops)
   - Number of cells

3. POWER:
   - Total power
   - Dynamic power
   - Leakage power

=============================================================================
Check individual reports in reports/<scenario>/ for detailed metrics.
=============================================================================
EOF

echo "Summary saved to: reports/comparison_summary.txt"
echo ""
echo "Done!"
