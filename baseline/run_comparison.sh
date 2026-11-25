#!/usr/bin/env bash
# One-command shared-port comparison (owner: Pranav).
#
# Captures a fresh request trace from the RTL, checks it against the tracked
# trace, shows the two overlap edges and replays the trace on one shared
# port. Use it to show the 5 vs 7 result live in the interview.
#
# Usage, from anywhere inside the repository:
#   ./baseline/run_comparison.sh
#
# Needs Icarus Verilog (iverilog, vvp) and Python 3.
# Exits non-zero if the trace or the cycle counts do not match.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TRACKED=baseline/harvard_trace.csv
FRESH=build/phase2_trace.csv

line() { printf '%s\n' "------------------------------------------------------------------"; }

for tool in iverilog vvp python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: '$tool' not found. Install Icarus Verilog and Python 3 first."
        exit 1
    fi
done

line
echo " Shared-port comparison: Harvard simulation vs one-port replay"
if git rev-parse --short HEAD >/dev/null 2>&1; then
    echo " Source revision: $(git rev-parse --short HEAD)"
fi
line

echo "[1/4] Capturing a fresh trace from rtl/*.v ..."
mkdir -p build
iverilog -g2012 -Wall -s trace_capture_tb -o build/trace.vvp \
    rtl/*.v baseline/trace_capture_tb.v
vvp build/trace.vvp > build/trace.log
grep '^TRACE,' build/trace.log | cut -d, -f2- > "$FRESH"
grep -E '^(RESULT|PASS|FAIL)' build/trace.log | sed 's/^/      /'

echo "[2/4] Comparing with the tracked trace ($TRACKED) ..."
if diff -u "$TRACKED" "$FRESH"; then
    echo "      MATCH: the fresh trace is identical to the tracked trace."
else
    echo "      MISMATCH: the trace changed. Check edges 3 and 4 and the source revision."
    exit 1
fi

echo "[3/4] The two overlap edges (fetch and data access on the same edge):"
awk -F, 'NR==1 {next}
         $5=="1" || $6=="1" {
             op = ($6=="1") ? "STORE" : "LOAD";
             printf "      Edge %s: fetch ROM[%s] + %s RAM[%s]\n", $1, $3, op, $7
         }' "$FRESH"

echo "[4/4] Replaying the same requests on one shared port ..."
echo
python3 baseline/replay_single_port.py "$FRESH" | tee build/replay.txt
echo

if grep -q 'Transfers: 7$' build/replay.txt &&
   grep -q 'Harvard 5 (simulation), single port 7 (modelled replay)' build/replay.txt; then
    line
    echo " RESULT: 7 transfers in 5 cycles (Harvard, simulation)"
    echo "         vs 7 cycles (one shared port, modelled replay): +2 cycles"
    line
else
    echo "UNEXPECTED: the counts differ from 7 transfers, 5 vs 7 cycles."
    exit 1
fi
