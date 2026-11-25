# Synthesis evidence and status

Owner: Neelanshu (memory RTL and synthesis)

## Phase II check

| Field | Value |
| --- | --- |
| Checked commit | `90244f1` (`main`). RTL, testbenches and synthesis files match `2863b0b`, the Phase I synthesis commit. |
| Check date | 2026-11-26 |
| Tools | Yosys 0.71+post (git sha1 `5628c132`), Icarus Verilog 13.0, macOS arm64 |
| Simulation | `scripts/sim.sh` exits 0. All three testbenches pass, with 24 checks in `memory_tb`. |
| Yosys rerun | All six stat and logic-depth files match the committed files byte for byte. |
| Aggregate counts | 54 LUTs (29 LUT2 + 16 LUT3 + 7 LUT4 + 2 LUT5), 38 FDRE, 2 RAM32M, before placement |
| Vivado timing | Pending. This machine has no Vivado, and the team has not confirmed the FPGA part. |
| Fmax | FPGA maximum operating frequency is unmeasured. |

The rerun refreshed the four Yosys logs. The Phase I logs predate the header comments in `instr_rom.v` and `data_ram.v`, so their source line numbers were four lines low. The remaining differences are run times, hashes and the order of ABC messages.

## Status

| Item | Status |
| --- | --- |
| Isolated memory test (`tb/memory_tb.v`) | Passes, 24 checks, Icarus Verilog 13.0 |
| Integrated suite (`scripts/sim.sh`) | Passes with these memories |
| Open-source synthesis (Yosys 0.71) | Done: generic gates and Xilinx 7-series mapping |
| Vivado synthesis and timing on the course FPGA part | **Pending.** The machine used here has no Vivado, and the team has not confirmed the course part. `vivado_synth.tcl` and `harvard_top.xdc` are ready to run once both exist. |
| Fmax | **Not measured.** It needs Vivado implementation timing on the course part. |

## Resource counts (Yosys, Xilinx 7-series mapping)

Yosys ran `synth_xilinx -family xc7`. These counts come from a pre-placement netlist, so treat them as estimates. Vivado may map differently.

The 54 LUTs exclude the RAM. A 7-series RAM32M occupies four LUT sites, so the two RAM32M primitives use eight more. Vivado lists those as "LUT as Memory". Compare the 54 with "LUT as Logic".

| Module | LUTs | Flip-flops (FDRE) | Memory | Other |
| --- | --- | --- | --- | --- |
| `instr_rom` | 6 (1 LUT2, 5 LUT4) | 0 | none | |
| `data_ram` | 16 LUT2 (read-enable gate) | 0 | 2 RAM32M (distributed RAM, 16 × 16 bits) | |
| `controller` | 32 | 38 | none | 5 CARRY4 for the 16-bit ADDI adder, 1 INV |
| `harvard_top` total | 54 | 38 | 2 RAM32M | 5 CARRY4, 1 BUFG, 2 IBUF, 17 OBUF |

The 38 flip-flops are the controller registers: PC (4), IR (16), ir_valid (1), ACC (16) and halted (1).

The RAM has an asynchronous (combinational) read, so Yosys maps it to LUT RAM (`$__XILINX_LUTRAM_SP_`) and not block RAM. The ROM is a constant case statement and becomes 6 LUTs. Neither module infers a latch (`check -assert` passes on the flattened design).

## Why a write to RAM[3] leaves ROM[3] alone

`instr_rom` is a constant case statement with one input, `i_addr`. It has no clock, write enable or data input, so no signal can change its contents. `data_ram` has its own array, `mem[0:15]`, and its own address bus, `d_addr`. At a rising edge with `d_we` high, it stores `d_wdata` in `mem[d_addr]`.

Index 3 selects a different word in each memory. `memory_tb` writes 5 to RAM[3], then reads ROM[3] as `3001` and RAM[3] as `0005`.

## Generic gate-level run

`synth -flatten -top harvard_top` maps the design to Yosys internal gates with no FPGA library.

- Standalone `data_ram`: 256 flip-flops plus 240 2-to-1 muxes. That is the full 16 × 16 array as registers with a 16-way read mux.
- Flattened `harvard_top`: 61 flip-flops and 243 cells. Yosys trims the RAM here because the demo ROM only places data addresses 0 and 3 on `ir[11:8]`, so the RAM keeps 2 of its 16 words. Use the standalone numbers when you report the memory's own cost.
- Longest combinational path in the flattened design: 20 generic cells (`yosys_generic_ltp.txt`). That is a logic-depth count, not a delay.

## What the timing evidence supports

Nothing here measures hardware timing yet. The testbench clock (10 ns in `tb/harvard_tb.v`) is a simulation setting and says nothing about how fast the circuit can run on an FPGA. Once someone has Vivado:

```sh
vivado -mode batch -source docs/synthesis/vivado_synth.tcl -tclargs <course-fpga-part>
```

The script reads all four RTL files, constrains `clk` at 10 ns (100 MHz) through `harvard_top.xdc`, runs synthesis and implementation, and writes utilization, timing summary and `check_timing` reports to `docs/synthesis/vivado/`. Label the post-synthesis timing an estimate. To estimate Fmax, tighten the period in the XDC until setup or hold fails, and record the tightest period that met timing on the post-route report. Also record the device, Vivado version and stage.

`harvard_top.xdc` constrains `clk` and sets no input or output delays. Expect `check_timing` to list `rst` as an input without a delay, and `acc[15:0]` and `halted` as outputs without one. Any Fmax from this XDC covers register-to-register paths, including paths through the RAM, and leaves the I/O paths out.

## Files

| File | Contents |
| --- | --- |
| `run_yosys.sh` | Reruns every Yosys result below |
| `yosys_xc7_stat.txt`, `yosys_xc7.log` | Whole design, Xilinx 7-series primitives |
| `yosys_xc7_data_ram_stat.txt`, `yosys_xc7_instr_rom_stat.txt` (+ logs) | Each memory on its own |
| `yosys_generic_stat.txt`, `yosys_generic_ltp.txt`, `yosys_generic.log` | Flattened generic gates and logic depth |
| `yosys_generic_data_ram_stat.txt` | Standalone RAM as generic flip-flops |
| `harvard_top.xdc`, `vivado_synth.tcl` | Ready-to-run Vivado flow (pending tools and part) |

## Reproduce

```sh
brew install icarus-verilog yosys
./scripts/sim.sh                     # all simulations, including memory_tb
./docs/synthesis/run_yosys.sh        # regenerates the Yosys files in this folder
```
