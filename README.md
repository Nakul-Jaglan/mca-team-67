# Instruction and Data Memory Hierarchy

Modern Computer Architecture, Project 9, Phase I. Team members are Nakul, Sudeshhna, Neelanshu, Puneet and Pranav.

The prototype uses a Harvard-style memory organization. A small Verilog controller fetches instructions from a read-only memory (ROM) and reads or writes numbers through a separate data memory (RAM). The two paths let the controller fetch the next instruction during a data read or write. The [prototype interface](docs/interface.md) defines the signals, the five-word demo program and its expected clock-by-clock behavior.

## Phase I handoff

| Owner | Work and files |
| --- | --- |
| Nakul | [Controller](rtl/controller.v), [top-level wiring](rtl/harvard_top.v), [prototype interface](docs/interface.md), integration and submission |
| Neelanshu | Instruction ROM at `rtl/instr_rom.v`, data RAM at `rtl/data_ram.v`, memory tests and synthesis evidence |
| Puneet | Integrated testbench at `tb/harvard_tb.v`, simulation instructions and waveform evidence |
| Sudeshhna | IEEE report under `docs/report/` and architecture diagram under `docs/diagrams/` |
| Pranav | Shared-memory comparison at `docs/baseline.md` and demo video link at `docs/demo/video.md` |

The controller, top level and interface are ready for the memory and verification handoffs. The commands below use the team's ROM, RAM and testbench once those files are present.

## Run the integrated prototype

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/usage/installation.html). Open a terminal in this project folder. On macOS, Linux or Git Bash, run these commands:

```sh
mkdir -p build
iverilog -g2012 -Wall -s harvard_tb -o build/harvard.vvp \
  rtl/controller.v rtl/harvard_top.v rtl/instr_rom.v rtl/data_ram.v \
  tb/harvard_tb.v
vvp build/harvard.vvp
```

The expected demo finishes with `halted = 1`, `acc = 6` and RAM word 3 holding 5. In the waveform, count the rising edges after reset. On edge 3, find instruction fetch and data write together. On edge 4, find instruction fetch and data read together.

## Submission checklist

- [ ] IEEE report PDF with Abstract, Literature Review, Proposed Solution, Individual Contributions and References.
- [ ] Viewable demo link. The recording is at most five minutes, names all five team members, explains the project and shows the prototype.
- [ ] Prototype RTL, testbench, block diagram, waveform evidence, shared-memory comparison and synthesis evidence or status.
- [ ] All five members' contributions visible in GitHub history.
- [ ] Repository link submitted through the [course form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform) by November 16, 2026 at 11:59 PM IST.
