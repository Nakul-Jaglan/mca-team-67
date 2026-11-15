#!/usr/bin/env bash
# ==============================================================================
# Script: sim.sh
# Project: MCA Project 9 - Instruction and Data Memory Hierarchy (Phase I)
# Owner: Puneet (Verification & Waveform Evidence)
#
# Description:
#   Automated build and simulation runner for the Harvard architecture prototype.
#   Compiles and runs:
#     1. Integrated system testbench (harvard_tb)
#     2. Directed load testbench (directed_load_tb)
#     3. Isolated memory smoke testbench (memory_tb)
#
# Usage:
#   ./scripts/sim.sh          # Run all simulations
#   ./scripts/sim.sh --wave   # Run simulations and launch GTKWave if installed
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=================================================================="
echo " MCA Project 9 (Team 67): Harvard Memory Hierarchy Simulation"
echo " Owner: Puneet | Verification Suite"
echo "=================================================================="

if ! command -v iverilog &> /dev/null; then
    echo "ERROR: 'iverilog' not found in PATH."
    echo "Install via Homebrew: brew install icarus-verilog"
    exit 1
fi

if ! command -v vvp &> /dev/null; then
    echo "ERROR: 'vvp' not found in PATH."
    exit 1
fi

mkdir -p build

echo ""
echo "[1/3] Compiling and running Integrated System Testbench (harvard_tb)..."
iverilog -g2012 -Wall -s harvard_tb -o build/harvard.vvp \
    rtl/*.v tb/harvard_tb.v
vvp build/harvard.vvp

echo ""
echo "[2/3] Compiling and running Directed LOAD Testbench (directed_load_tb)..."
iverilog -g2012 -Wall -s directed_load_tb -o build/directed_load.vvp \
    rtl/controller.v tb/directed_load_tb.v
vvp build/directed_load.vvp

echo ""
echo "[3/3] Compiling and running Isolated Memory Testbench (memory_tb)..."
iverilog -g2012 -Wall -s memory_tb -o build/memory.vvp \
    rtl/instr_rom.v rtl/data_ram.v tb/memory_tb.v
vvp build/memory.vvp

echo ""
echo "=================================================================="
echo " ALL SIMULATIONS PASSED CLEANLY!"
echo " Waveform files generated:"
echo "   - build/harvard.vcd"
echo "   - build/directed_load.vcd"
echo "=================================================================="

if [[ "${1:-}" == "--wave" || "${1:-}" == "-w" ]]; then
    if command -v gtkwave &> /dev/null; then
        echo "Launching GTKWave on build/harvard.vcd..."
        gtkwave build/harvard.vcd &
    else
        echo "NOTE: 'gtkwave' is not installed or not in PATH."
        echo "Install via Homebrew: brew install --cask gtkwave"
        echo "Pre-rendered waveform evidence is available under docs/evidence/."
    fi
fi
