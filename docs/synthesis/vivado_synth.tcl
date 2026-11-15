# Vivado batch synthesis and implementation for harvard_top.
# Usage (from the repo root):
#   vivado -mode batch -source docs/synthesis/vivado_synth.tcl -tclargs <course-fpga-part>
# Example part: xc7a35tcpg236-1 (Basys 3). Use the part the course names.
if {[llength $argv] < 1} { error "Pass the FPGA part, e.g. -tclargs xc7a35tcpg236-1" }
set part [lindex $argv 0]
set out  docs/synthesis/vivado

file mkdir $out
read_verilog [list rtl/controller.v rtl/instr_rom.v rtl/data_ram.v rtl/harvard_top.v]
read_xdc docs/synthesis/harvard_top.xdc

synth_design -top harvard_top -part $part
report_utilization     -file $out/post_synth_utilization.rpt
report_timing_summary  -file $out/post_synth_timing_summary.rpt
check_timing           -file $out/post_synth_check_timing.rpt

opt_design
place_design
route_design
report_utilization     -file $out/post_route_utilization.rpt
report_timing_summary  -file $out/post_route_timing_summary.rpt
puts "Vivado [version -short] on $part. Reports in $out/"
