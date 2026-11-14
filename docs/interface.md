# Prototype interface

`harvard_top` connects a small instruction controller to an instruction ROM and a separate data RAM. Each memory holds sixteen 16-bit words. A 4-bit address selects a word directly. ROM word 3 and RAM word 3 are separate locations.

## Module connections

| Module | Inputs | Outputs |
| --- | --- | --- |
| `harvard_top` | `clk`, `rst` | `acc[15:0]`, `halted` |
| `controller`, instance `control` | `clk`, `rst`, `i_rdata[15:0]`, `d_rdata[15:0]` | `i_req`, `i_addr[3:0]`, `d_re`, `d_we`, `d_addr[3:0]`, `d_wdata[15:0]`, `acc[15:0]`, `halted` |
| `instr_rom`, instance `rom` | `i_addr[3:0]` | `i_rdata[15:0]` |
| `data_ram`, instance `ram` | `clk`, `d_re`, `d_we`, `d_addr[3:0]`, `d_wdata[15:0]` | `d_rdata[15:0]` |

- **Clock and reset.** State changes on the rising edge of `clk`. Active-high `rst` clears the controller's PC, instruction register, instruction-valid bit, accumulator and halt flag at that edge. It also suppresses `i_req`, `d_re` and `d_we` while asserted. The data RAM starts with unspecified contents. The program writes a word before reading it.
- **Instruction path.** ROM continuously returns the instruction at `i_addr`, which is the PC. When `i_req` is high at a rising edge, the controller captures that instruction in its instruction register and increments PC by one word. The 4-bit PC wraps from 15 to 0.
- **Data path.** The current instruction's address field drives `d_addr`. When `d_re` is high, RAM returns the selected word combinationally. The controller captures it into ACC on the rising edge. When `d_we` is high at a rising edge, RAM stores the old ACC value from `d_wdata`. The read output is zero with `d_re` low. The controller asserts at most one data enable at a time.
- **Simulation signals.** With a top-level instance named `dut`, the bus signals above are available as `dut.i_req`, `dut.d_we` and so on. Controller registers are available as `dut.control.pc`, `dut.control.ir` and `dut.control.ir_valid`. Check requests immediately before the rising edge and check updated registers after the edge settles.

## Instruction encoding

Bits `[15:12]` select the operation. LOAD and STORE use bits `[11:8]` as the data address. ADDI uses bits `[7:0]` as an unsigned immediate. Bits unused by an operation are ignored.

| Opcode (hex) | Operation |
| --- | --- |
| `0` | NOP leaves ACC unchanged. |
| `1` | LOAD copies a RAM word to ACC. |
| `2` | STORE copies ACC to a RAM word. |
| `3` | ADDI adds the zero-extended immediate to ACC, wrapping at 16 bits. |
| `F` | HALT suppresses the next fetch and sets `halted` at the rising edge. Requests stay idle until reset. |
| All others | Behave like NOP. |

## Demo program and expected trace

The ROM image at word indices 0 through 4 is `3005 2300 1300 3001 F000` in hex. Fill unused ROM entries with `F000`. The first rising edge after reset is edge 1.

| Edge | Fetch | Execute using the old instruction register |
| --- | --- | --- |
| 1 | ROM[0] = `3005` | The instruction register is invalid before this edge. ACC stays 0. |
| 2 | ROM[1] = `2300` | ADDI 5. ACC becomes 5. |
| 3 | ROM[2] = `1300` | STORE 5 into RAM[3]. |
| 4 | ROM[3] = `3001` | LOAD 5 from RAM[3] into ACC. |
| 5 | ROM[4] = `F000` | ADDI 1. ACC becomes 6. |
| 6 | Idle | HALT. `halted` becomes 1. |
| 7 onward | Idle | Requests stay low. ACC stays 6. |

Edges 3 and 4 each serve two memory operations. The final ACC is 6 and RAM[3] holds 5.
