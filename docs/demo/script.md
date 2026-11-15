# Demo video script

Owner: Pranav. Target length is about 4 minutes, with a hard cap of 5 minutes. Record at 1080p if you can. Make the terminal font and waveform labels larger before recording.

## Before recording

- [ ] Pull the integrated commit from `main` (`git pull`). Recorded from `afbdfd9`.
- [ ] Run `./scripts/sim.sh` once and check that it ends with `ALL SIMULATIONS PASSED CLEANLY!`.
- [ ] Open these files:
  - Block diagram: [`docs/diagrams/harvard-architecture.png`](../diagrams/harvard-architecture.png)
  - Program: [`rtl/instr_rom.v`](../../rtl/instr_rom.v)
  - Annotated waveform: [`docs/evidence/harvard-waveform.png`](../evidence/harvard-waveform.png)
  - Comparison: [docs/baseline.md](../baseline.md)
  - The GitHub README
- [ ] GTKWave isn't needed. Puneet's annotated waveform image and [`docs/evidence/simulation_pass.log`](../evidence/simulation_pass.log) come from the same build. To open the live waveform instead, run `brew install --cask gtkwave` and then `./scripts/sim.sh --wave`.
- [ ] Use the same recorder and microphone settings as the 10-second test clip (see [practice-table.md](practice-table.md)).
- [ ] Get confirmed contribution lines from each member.

## Script

### 0:00–0:25 · Idea and team

**On screen:** title card with the project name and all five names: Nakul, Sudeshhna, Neelanshu, Puneet, Pranav.

> "This is Project 9 for Modern Computer Architecture: an instruction and data memory hierarchy. Our team is Nakul, Sudeshhna, Neelanshu, Puneet and Pranav. We built a small Harvard-style processor. Instructions and data are kept in separate memories with separate connections, so the processor can fetch its next instruction while it reads or writes data."

### 0:25–1:00 · Block diagram

**On screen:** Sudeshhna's block diagram.

> "The controller is in the middle. On the left is a dedicated instruction ROM: 16 words of 16 bits that the controller can only read. On the right is a separate data RAM, also 16 by 16, that it can read and write. Each memory has its own address, enable and data signals. The controller keeps a program counter, an instruction register and an accumulator, and updates them on each rising clock edge."

### 1:00–1:35 · Program and simulation

**On screen:** the ROM contents (`3005 2300 1300 3001 F000`), then the terminal.

> "The program is five words long. Add 5, store it in data word 3, load it back, add 1, and halt. I'll compile and run the testbench now."

Run `./scripts/sim.sh` (Puneet's runner, which runs all three testbenches). Point to the edge table and `PASS: All 7 cycle-by-cycle assertions verified successfully!`.

> "The test passes. The processor halted with the accumulator at 6, and data RAM word 3 still holds 5."

### 1:35–2:45 · Waveform

**On screen:** zoomed waveform with edges counted from reset.

> "Here is the waveform. I'm counting rising edges from the end of reset. On edges 1 and 2 only the instruction side is busy: `i_req` is high and `i_addr` steps 0, 1."

> "Edge 3 is the first overlap. `i_req` fetches ROM word 2. At the same time `d_we` is high, `d_addr` is 3 and `d_wdata` is 5. That's the STORE. Two memory operations happen on one clock edge."

> "Edge 4 is the second overlap. The fetch reads ROM word 3 while `d_re` is high, and `d_rdata` returns 5 from RAM word 3. That's the LOAD."

> "Edge 5 fetches the HALT instruction. On edge 6 HALT runs. `halted` goes high and every request line stays low after that."

### 2:45–3:25 · Shared-port comparison

**On screen:** the results tables in [docs/baseline.md](../baseline.md), or the output of `python3 baseline/replay_single_port.py`.

> "To show what the separate paths are worth, I replayed this exact request trace on a model with one shared memory port. Code goes in indices 0 to 15 and data in 16 to 31, with one transfer per cycle. When a fetch and a data access arrive together, the data access goes first and the fetch waits a cycle."

> "The Harvard design serves all seven transfers in 5 cycles, measured in simulation. The single port needs 7. That's two extra cycles: 1.4 transfers per cycle against 1.0. The single-port number is a modelled replay of the measured trace, not a runtime measurement of a second CPU."

### 3:25–4:10 · Repository and contributions

**On screen:** the GitHub README, then scroll to the report, `rtl/`, the testbench, the waveform evidence and `docs/baseline.md`.

> "Everything is in our GitHub repository: the report, the Verilog code, the testbench, the waveform evidence and this comparison."

Read one line for each person. These follow the Individual Contributions section of the report and the work on GitHub.

> "Nakul designed the controller, the top-level wiring and the interface, and integrated everything. Neelanshu built the instruction ROM and data RAM, the memory tests and the synthesis evidence. Puneet wrote the integrated and directed testbenches and the simulation runner, and produced the waveform evidence. Sudeshhna wrote the IEEE report and drew the block diagram. I built the shared-port comparison and made this video. Thanks for watching."

## After recording

- [ ] Watch the whole export with headphones. Check the spoken names, audio, readable labels and length (under 5:00).
- [ ] Upload to a platform the course accepts. Set access so the evaluator can view it.
- [ ] Open the link in a signed-out or private window to test it.
- [ ] Put the link in [video.md](video.md), commit, and send it to Nakul by **6:00 PM IST, 16 November**.
