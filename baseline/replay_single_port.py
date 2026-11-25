#!/usr/bin/env python3
"""Replay the Harvard request trace on a single shared memory port.

Owner: Pranav. Reads the per-edge trace made by baseline/trace_capture_tb.v
and compares two memory organisations serving the same demand:

* Harvard (split paths). Instruction ROM and data RAM have separate ports,
  so a fetch and a data access in the same edge finish in one cycle.
* Single shared port (modelled). One memory holds code at indices 0-15 and
  data at indices 16-31. It serves one transfer per cycle.

Replay rules:
1. Each rising edge that issues requests is one batch, kept in trace order.
2. Every transfer takes one cycle. The port serves one transfer per cycle.
3. In a two-request batch the data access goes first and the fetch waits
   one cycle. The next batch starts only after the current one clears, so
   STORE stays before LOAD and all five fetches stay in order.
4. Edges with no requests (the idle HALT edge and later) are left out.
   Cycles are counted from the first memory transfer through the last.

The single-port numbers are a modelled estimate made from the measured
trace. They are not a measured CPU runtime.

Usage:
    python3 baseline/replay_single_port.py [baseline/harvard_trace.csv] [--markdown]
"""

import csv
import sys
from fractions import Fraction
from pathlib import Path

CODE_BASE = 0    # shared-memory index of ROM word 0
DATA_BASE = 16   # shared-memory index of RAM word 0


def load_batches(path):
    """Return one batch per edge that issued at least one memory request."""
    batches = []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            edge = int(row["edge"])
            data = None
            if row["d_we"] == "1":
                data = ("STORE", int(row["d_addr"]))
            elif row["d_re"] == "1":
                data = ("LOAD", int(row["d_addr"]))
            fetch = int(row["i_addr"]) if row["i_req"] == "1" else None
            if data is None and fetch is None:
                continue  # idle edge, outside the memory-service metric
            batches.append({"edge": edge, "data": data, "fetch": fetch})
    return batches


def describe(batch):
    parts = []
    if batch["data"]:
        op, addr = batch["data"]
        parts.append(f"{op} RAM[{addr}]")
    if batch["fetch"] is not None:
        parts.append(f"fetch ROM[{batch['fetch']}]")
    text = " + ".join(parts)
    return text[0].upper() + text[1:]


def replay(batches):
    rows = []
    harvard_cycle = 0
    shared_cycle = 0
    transfers = 0
    for batch in batches:
        harvard_cycle += 1  # both ports work in parallel
        served = []
        if batch["data"]:  # data first
            shared_cycle += 1
            op, addr = batch["data"]
            served.append(f"{shared_cycle} {op} (idx {DATA_BASE + addr})")
            transfers += 1
        if batch["fetch"] is not None:  # then the deferred fetch
            shared_cycle += 1
            served.append(f"{shared_cycle} fetch (idx {CODE_BASE + batch['fetch']})")
            transfers += 1
        n = (batch["data"] is not None) + (batch["fetch"] is not None)
        harvard_text = f"{harvard_cycle} (both)" if n == 2 else str(harvard_cycle)
        rows.append((batch["edge"], describe(batch), harvard_text, ", ".join(served)))
    return rows, harvard_cycle, shared_cycle, transfers


def main(argv):
    markdown = "--markdown" in argv
    args = [a for a in argv if not a.startswith("--")]
    default = Path(__file__).with_name("harvard_trace.csv")
    path = Path(args[0]) if args else default

    rows, harvard, shared, transfers = replay(load_batches(path))

    if markdown:
        print("| Edge | Request batch | Harvard service cycle (simulation) | Single-port cycle (modelled replay, shared index) |")
        print("| --- | --- | --- | --- |")
        for edge, batch, h, s in rows:
            print(f"| {edge} | {batch} | {h} | {s} |")
    else:
        print(f"{'Edge':<5} {'Request batch':<32} {'Harvard':<10} Single port (modelled replay)")
        for edge, batch, h, s in rows:
            print(f"{edge:<5} {batch:<32} {h:<10} {s}")

    print()
    print(f"Transfers: {transfers}")
    print(f"Memory-service cycles: Harvard {harvard} (simulation), single port {shared} (modelled replay)")
    print(f"Extra cycles with one port: {shared - harvard}")
    rh, rs = Fraction(transfers, harvard), Fraction(transfers, shared)
    print(f"Service rate: Harvard {transfers}/{harvard} = {float(rh):.2f}, "
          f"single port {transfers}/{shared} = {float(rs):.2f} transfers per cycle")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
