#!/bin/bash
# =============================================================================
# Run All Synthesis Scenarios - RISC-V Pipeline
# =============================================================================
# Usage: ./run_all.sh [scenario]
#   ./run_all.sh           - Run all 3 scenarios
#   ./run_all.sh baseline  - Run only baseline
#   ./run_all.sh ppa1      - Run only ppa1
#   ./run_all.sh ppa2      - Run only ppa2
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

run_scenario() {
    local scenario=$1
    echo ""
    echo "=========================================="
    echo "  Running Synthesis: $scenario"
    echo "=========================================="
    genus -f run_${scenario}.tcl -log logs/${scenario}.log
    echo "  Completed: $scenario"
}

# Create logs directory
mkdir -p logs

if [ -z "$1" ]; then
    # Run all scenarios
    echo "Running all synthesis scenarios..."
    run_scenario "baseline"
    run_scenario "ppa1"
    run_scenario "ppa2"
    
    echo ""
    echo "=========================================="
    echo "  All Scenarios Complete!"
    echo "=========================================="
    echo "  Reports: ./reports/{baseline,ppa1,ppa2}/"
    echo "  Outputs: ./output/{baseline,ppa1,ppa2}/"
    echo "  Logs:    ./logs/"
    echo "=========================================="
else
    # Run specific scenario
    case $1 in
        baseline|ppa1|ppa2)
            run_scenario "$1"
            ;;
        *)
            echo "Error: Unknown scenario '$1'"
            echo "Valid options: baseline, ppa1, ppa2"
            exit 1
            ;;
    esac
fi
