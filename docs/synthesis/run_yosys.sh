#!/usr/bin/env bash
# Re-run the open-source synthesis evidence in docs/synthesis/.
# Needs Yosys (macOS: brew install yosys). Run from anywhere.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R=../../rtl
RTL="$R/controller.v $R/instr_rom.v $R/data_ram.v $R/harvard_top.v"

# Whole design, generic gates, flattened, with a structural check and logic depth.
yosys -q -l yosys_generic.log -p "read_verilog $RTL; synth -flatten -top harvard_top; check -assert; \
  tee -o yosys_generic_stat.txt stat; tee -o yosys_generic_ltp.txt ltp -noff" >/dev/null

# Whole design mapped to Xilinx 7-series primitives (LUT, FDRE, RAM32M).
yosys -q -l yosys_xc7.log -p "read_verilog $RTL; synth_xilinx -family xc7 -top harvard_top; \
  tee -o yosys_xc7_stat.txt stat" >/dev/null

# Each memory on its own, so the fixed program cannot trim unused RAM words.
for m in data_ram instr_rom; do
  yosys -q -l "yosys_xc7_${m}.log" -p "read_verilog $R/$m.v; synth_xilinx -family xc7 -top $m; \
    tee -o yosys_xc7_${m}_stat.txt stat" >/dev/null
done
yosys -q -p "read_verilog $R/data_ram.v; synth -top data_ram; tee -o yosys_generic_data_ram_stat.txt stat" >/dev/null

echo "Yosys synthesis finished. Stats are in docs/synthesis/*_stat.txt"
