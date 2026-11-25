# Interview walkthrough: shared-port comparison

Owner: Pranav. This is a short live walkthrough of the 5 vs 7 result, taking about 90 seconds. Anyone on the team can run it. The full method is in [docs/baseline.md](../baseline.md).

## Before the interview

- [ ] Run `git pull` on `main` and check that the commit matches the one the team agreed for the report and demo.
- [ ] Run `./baseline/run_comparison.sh` once, and check that it ends with `RESULT: 7 transfers in 5 cycles ... vs 7 cycles`.
- [ ] Make the terminal text larger (Cmd and + a few times).
- [ ] Keep the [demo video](video.md) open in a browser tab as a backup. Its link was last checked as viewable by anyone on 26 Nov 2026.
- [ ] If the laptop can't run Icarus Verilog, show the tables in [docs/baseline.md](../baseline.md) on GitHub instead.

## Live steps

**1. Run the script.**

```sh
./baseline/run_comparison.sh
```

> "This script takes a fresh trace from our final Verilog, checks it against the trace we committed, and then replays the same requests on a model with only one memory port."

**2. Point at `[2/4] MATCH`.**

> "The new trace is identical to the committed one, so the numbers in the report come from the final build."

**3. Point at the two overlap lines in `[3/4]`.**

> "In the demo, edges 3 and 4 each have two requests. On edge 3 we fetch ROM word 2 and store 5 into RAM word 3. On edge 4 we fetch ROM word 3 and load 5 back from RAM word 3."

**4. Point at rows 3 and 4 of the replay table.**

> "Harvard serves both requests on each of those edges, because instruction memory and data memory have separate ports. The one-port replay splits each pair over two cycles: the data access first, then the fetch."

**5. Point at the `RESULT` box.**

> "So these seven transfers take seven service cycles instead of five. That's two extra cycles, or 1.4 transfers per cycle against 1.0. The 5 comes from simulation, and the 7 is a modelled replay of the same trace."

## The two overlap rows

| Original batch | Split paths (simulation) | Single shared port (modelled replay) |
| --- | --- | --- |
| Edge 3: STORE RAM[3] + fetch ROM[2] | Both in cycle 3 | STORE in cycle 3, fetch in cycle 4 |
| Edge 4: LOAD RAM[3] + fetch ROM[3] | Both in cycle 4 | LOAD in cycle 5, fetch in cycle 6 |

Every other edge has a single fetch, so it takes one cycle in both designs. Edge 5's fetch is pushed to cycle 7 only because the two pairs before it each took an extra cycle.

## Likely questions

**What if the program only fetched instructions?**
Then there would be no port conflict under this model. Each cycle has one fetch and the shared port can serve it, so both designs need one cycle per fetch. The Harvard advantage only shows up when a fetch and a data access happen on the same edge.

**Why does the data access go first?**
The instruction that is executing needs its data now, while the next fetch can wait a cycle. It doesn't change the count, though. Serving the fetch first still takes two cycles per conflicting pair, so the total is still 7.

**Is the 7 measured?**
No. The 5 is measured in simulation of our Verilog. The 7 is a model: the same seven requests replayed on one port with one transfer per cycle and no extra wait states. A real single-port CPU would need its own design and its own measurement.

**Why not count edge 6?**
HALT takes effect on edge 6, and no memory request is served then. The metric counts from the first memory transfer to the last, so idle edges are left out of both designs.

**Where do the code and data go in the single memory?**
Code is at indices 0 to 15 and data at 16 to 31 of one 32-word memory, so RAM[3] becomes shared index 19. The script prints these indices in the replay table.

**Does the result apply to bigger programs?**
Only this workload was measured. The model says the gain depends on how often a fetch and a data access fall on the same edge. More loads and stores mean more conflicts on one port.

## What everyone should be able to explain

| Demo moment | Explanation |
| --- | --- |
| System overview | The program counter selects the next instruction, the instruction register holds the current instruction, and the accumulator holds the working number. |
| Rising edges 3 and 4 | Edge 3 fetches ROM[2] and writes 5 to RAM[3]. Edge 4 fetches ROM[3] and reads 5 from RAM[3]. The two paths use separate connections. |
| Rising edge 6 | HALT takes effect. The controller ends with ACC = 6 and halted = 1, and RAM[3] still holds 5. |
