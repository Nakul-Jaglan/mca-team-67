# Shared-port baseline

Owner: Pranav. This page compares the Harvard prototype with a single-memory design that has one shared port. Both designs serve the same request trace.

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

| Edge | Request batch | Harvard service cycle | Single-port replay cycle |
| --- | --- | --- | --- |
| 1 | Fetch ROM[0] | 1 | 1 |
| 2 | Fetch ROM[1] | 2 | 2 |
| 3 | STORE RAM[3] + fetch ROM[2] | 3 (both) | 3 STORE, 4 fetch |
| 4 | LOAD RAM[3] + fetch ROM[3] | 4 (both) | 5 LOAD, 6 fetch |
| 5 | Fetch ROM[4] | 5 | 7 |

| Measure | Harvard (split paths) | Single shared port (modelled) |
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

## Evidence status

- The trace captured from `rtl/controller.v` and `rtl/harvard_top.v` matches the expected trace in [the interface](interface.md). There is a fetch + STORE on edge 3, a fetch + LOAD on edge 4, final ACC = 6 and RAM[3] = 5.
- **Pending:** The committed trace was captured with stand-in ROM and RAM models written to the interface. Neelanshu's `rtl/instr_rom.v` and `rtl/data_ram.v` were not merged yet. After the memories merge, regenerate the trace and check it against Puneet's testbench trace. If the CSV does not change, this result stands as measured on the integrated build.

## Reproduce

Run these commands from the repository root. Icarus Verilog and Python 3 are required.

```sh
mkdir -p build
iverilog -g2012 -Wall -s trace_capture_tb -o build/trace.vvp \
  rtl/controller.v rtl/harvard_top.v rtl/instr_rom.v rtl/data_ram.v \
  baseline/trace_capture_tb.v
vvp build/trace.vvp | grep '^TRACE,' | cut -d, -f2- > baseline/harvard_trace.csv
python3 baseline/replay_single_port.py
```

Expected ending:

```
Transfers: 7
Memory-service cycles: Harvard 5, single port 7 (modelled)
Extra cycles with one port: 2
Service rate: Harvard 7/5 = 1.40, single port 7/7 = 1.00 transfers per cycle
```

Add `--markdown` to print the result table in Markdown for the report.
