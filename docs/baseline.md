# Shared-port baseline

Owner: Pranav. This page compares the Harvard prototype with a single-memory design that has one shared port. Both designs serve the same request trace.

> **Phase II summary.** The trace was recaptured from the final RTL at commit `cc58393` and matched the tracked trace exactly. The demo program makes 7 memory transfers: 5 instruction fetches and 2 data operations. The Harvard prototype serves them in **5 memory-service cycles (simulation)**. Replaying the same requests on one shared port takes **7 cycles (modelled replay)**, which is 2 extra cycles. This result applies only to this workload and to a port model with one transfer per cycle, no extra wait states, and data first on a conflict.

## Question

The Harvard prototype has two memory paths. The instruction ROM and the data RAM can each serve one request on the same rising edge. If code and data were in one memory with one port, how many memory-service cycles would the same request trace need?

## Method

1. **Capture the split-path trace.** [`baseline/trace_capture_tb.v`](../baseline/trace_capture_tb.v) runs `harvard_top` from reset. Just before each rising edge it records `i_req`, `i_addr`, `d_re`, `d_we` and `d_addr`. The result is [`baseline/harvard_trace.csv`](../baseline/harvard_trace.csv). Edge 1 is the first rising edge after reset, as in [the interface](interface.md).
2. **Group requests into batches.** Each edge that issues requests is one batch. The demo program gives five batches with seven transfers in total: five instruction fetches and two data operations.
3. **Replay the same demand on one port.** [`baseline/replay_single_port.py`](../baseline/replay_single_port.py) applies these rules:
   - Code and data use separate logical regions of one 32-word memory. Code is at indices 0 to 15 (ROM word *n* goes to index *n*). Data is at indices 16 to 31 (RAM word *n* goes to index 16 + *n*). So RAM[3] is shared index 19.
   - The port serves one transfer per cycle. Every transfer takes one cycle, the same as on the Harvard paths.
   - Batches are served one at a time, in trace order. The next batch starts only after the current batch clears.
   - In a two-request batch the data access goes first and the fetch waits one cycle. This keeps STORE before LOAD and keeps all five fetches in order.
4. **Count the metric.** Memory-service cycles run from the first memory transfer through the last. The idle HALT edge (edge 6) and later edges issue no requests, so they are not counted.

## Result

| Edge | Request batch | Harvard service cycle (simulation) | Single-port cycle (modelled replay) |
| --- | --- | --- | --- |
| 1 | Fetch ROM[0] | 1 | 1 |
| 2 | Fetch ROM[1] | 2 | 2 |
| 3 | STORE RAM[3] + fetch ROM[2] | 3 (both) | 3 STORE, 4 fetch |
| 4 | LOAD RAM[3] + fetch ROM[3] | 4 (both) | 5 LOAD, 6 fetch |
| 5 | Fetch ROM[4] | 5 | 7 |

| Measure | Harvard, split paths (simulation) | Single shared port (modelled replay) |
| --- | --- | --- |
| Transfers served | 7 | 7 |
| Memory-service cycles | 5 | 7 |
| Extra cycles | none | +2 |
| Service rate | 7/5 = 1.40 transfers per cycle | 7/7 = 1.00 transfer per cycle |

On edges 3 and 4 the Harvard design serves a fetch and a data access together. One shared port must put those pairs in a row, so it needs two extra cycles for this trace.

## Assumptions and limits

- **The single-port number is a modelled estimate.** It comes from replaying the trace, not from simulating a single-port CPU. A real CPU runtime comparison would need its own RTL and its own measured baseline.
- The model has no extra arbitration delay, bank conflicts or wait states. Both designs use the same one-cycle service per transfer.
- Only the demo program in [the interface](interface.md) was replayed: `3005 2300 1300 3001 F000`.
- On a conflict the data access goes first. Serving the fetch first instead still gives 7 cycles, because each conflicting pair takes two cycles in either order.
- The extra cycles come only from conflicts. A program that only fetched instructions would have no conflicts under this model, and both designs would need one cycle per fetch.

## Evidence status

### Phase II final capture

| Item | Value |
| --- | --- |
| Capture commit | `cc58393` (`main` after PR #4, Neelanshu's Phase II synthesis update) |
| RTL changes since Phase I | None. Nothing in `rtl/`, `tb/` or the trace testbench changed after `afbdfd9`, which is the commit the Phase I video was recorded from. Only `docs/synthesis/` and `docs/demo/` changed. |
| Fresh trace vs tracked trace | `diff -u` printed nothing, so they match exactly |
| Trace capture testbench | PASS: ACC = 6, RAM[3] = 5, halted = 1 |
| `./scripts/sim.sh` | All 3 testbenches pass (harvard_tb 7 assertions, directed LOAD, memory_tb 24 checks) |
| Replay result | 7 transfers. Harvard 5 cycles (simulation), single port 7 cycles (modelled replay), +2 |

Because the trace did not change, `baseline/harvard_trace.csv` is unchanged and no CSV update had to be coordinated with Puneet.

### Phase I

- **Confirmed on the integrated build.** The trace was regenerated with the team's real `rtl/instr_rom.v` and `rtl/data_ram.v` on `main`, together with `rtl/controller.v` and `rtl/harvard_top.v`. The new CSV is byte-for-byte identical to the committed [`baseline/harvard_trace.csv`](../baseline/harvard_trace.csv). The trace was first captured with stand-in memories written to the interface. The replay still gives 5 vs 7.
- The ROM and RAM on Neelanshu's `phase1/neelanshu` branch only add comments. A trace captured with that version is also identical.
- The trace agrees with Puneet's integrated testbench ([`tb/harvard_tb.v`](../tb/harvard_tb.v), log in [`docs/evidence/simulation_pass.log`](evidence/simulation_pass.log)). That testbench checks a fetch + STORE on edge 3, a fetch + LOAD on edge 4, HALT on edge 6, and final ACC = 6 and RAM[3] = 5.
- The Harvard counts (5 cycles, 7 transfers) are measured from simulation. The single-port count (7 cycles) is still a modelled replay of that measured trace.

## Reproduce

Icarus Verilog and Python 3 are required. Run everything from the repository root.

**One command.** This is the quickest way, and it's what to use live in the interview:

```sh
./baseline/run_comparison.sh
```

The script captures a fresh trace into `build/phase2_trace.csv`, checks it against the tracked trace, lists the two overlap edges, and runs the replay. It ends with:

```
 RESULT: 7 transfers in 5 cycles (Harvard, simulation)
         vs 7 cycles (one shared port, modelled replay): +2 cycles
```

It exits with an error if the trace or the counts change.

**Step by step.** The same thing as separate commands:

```sh
git rev-parse --short HEAD
mkdir -p build
iverilog -g2012 -Wall -s trace_capture_tb -o build/trace.vvp \
  rtl/*.v baseline/trace_capture_tb.v
vvp build/trace.vvp | grep '^TRACE,' | cut -d, -f2- \
  > build/phase2_trace.csv
diff -u baseline/harvard_trace.csv build/phase2_trace.csv
python3 baseline/replay_single_port.py build/phase2_trace.csv --markdown
```

If `diff` prints nothing, the fresh trace matches the tracked one. The replay ends with:

```
Transfers: 7
Memory-service cycles: Harvard 5 (simulation), single port 7 (modelled replay)
Extra cycles with one port: 2
Service rate: Harvard 7/5 = 1.40, single port 7/7 = 1.00 transfers per cycle
```

`--markdown` prints the per-edge table in Markdown for the report.
