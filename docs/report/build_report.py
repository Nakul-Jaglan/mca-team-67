"""Build the Phase I IEEE-format report (phase1-report.docx) for Project 9.

Owner: Sudeshhna. The text follows docs/interface.md, docs/baseline.md and
baseline/harvard_trace.csv. Yellow-highlighted text marks evidence that is
still pending from teammates; replace it before exporting the final PDF.

Usage (from the repository root):
    pip install python-docx
    python3 docs/report/build_report.py
    # then export PDF from Word (File > Save As > PDF) or with LibreOffice:
    soffice --headless --convert-to pdf --outdir docs/report docs/report/phase1-report.docx
    mv docs/report/phase1-report.pdf docs/report/phase1-report.pdf   # name already matches

Once someone hand-edits the .docx, edit the .docx directly instead of rerunning this script.
"""
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_COLOR_INDEX
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "report" / "phase1-report.docx"
FIG1 = ROOT / "docs" / "diagrams" / "harvard-architecture.png"
FIG2 = ROOT / "docs" / "evidence" / "harvard-waveform.png"
REPO = "https://github.com/Nakul-Jaglan/mca-team-67"

TITLE = "Instruction and Data Memory Hierarchy: A Harvard-Style Controller with Separate Instruction and Data Paths"
AUTHORS = [  # (name, line 2) -- confirm full names with the team
    ("Nakul Jaglan", "Controller and integration"),
    ("Sudeshhna Behera", "Report and architecture"),
    ("Neelanshu", "Memories and synthesis"),
    ("Puneet", "Verification"),
    ("Pranav Sehgal", "Baseline and demo video"),
]
AFFIL = "Modern Computer Architecture, Project 9 (MCA Team 67)"

doc = Document()

# ---------- base styles (IEEE conference: Times New Roman 10 pt) ----------
normal = doc.styles["Normal"]
normal.font.name = "Times New Roman"
normal.element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
normal.font.size = Pt(10)
normal.paragraph_format.space_after = Pt(0)
normal.paragraph_format.space_before = Pt(0)
normal.paragraph_format.line_spacing = 1.0


def set_cols(section, num, space_mm=4.22):
    sectPr = section._sectPr
    cols = sectPr.find(qn("w:cols"))
    if cols is None:
        cols = OxmlElement("w:cols")
        sectPr.append(cols)
    cols.set(qn("w:num"), str(num))
    cols.set(qn("w:space"), str(int(space_mm / 25.4 * 1440)))


def page_setup(section):
    # IEEE A4 conference template margins
    section.page_width, section.page_height = Mm(210), Mm(297)
    section.top_margin = Mm(19)
    section.bottom_margin = Mm(43)
    section.left_margin = section.right_margin = Mm(14.32)


def para(text="", size=10, bold=False, italic=False, align=WD_ALIGN_PARAGRAPH.JUSTIFY,
         indent=True, after=0, before=0):
    p = doc.add_paragraph()
    p.alignment = align
    pf = p.paragraph_format
    pf.first_line_indent = Mm(3.6) if indent else None
    pf.space_after, pf.space_before = Pt(after), Pt(before)
    if text:
        add_runs(p, text, size=size, bold=bold, italic=italic)
    return p


def add_runs(p, text, size=10, bold=False, italic=False):
    """Plain text with inline markup: **bold**, `code`, {{pending}} (yellow highlight)."""
    import re
    for tok in re.split(r"(\*\*.+?\*\*|`.+?`|\{\{.+?\}\})", text):
        if not tok:
            continue
        r = p.add_run()
        r.font.size = Pt(size)
        r.bold, r.italic = bold, italic
        if tok.startswith("**"):
            r.text, r.bold = tok[2:-2], True
        elif tok.startswith("`"):
            r.text = tok[1:-1]
            r.font.name = "Courier New"
            r.font.size = Pt(size - 1)
        elif tok.startswith("{{"):
            r.text = tok[2:-2]
            r.font.highlight_color = WD_COLOR_INDEX.YELLOW
        else:
            r.text = tok
    return p


ROMAN = ["I", "II", "III", "IV", "V", "VI"]
_h1 = [0]
_h2 = [0]


def h1(text, numbered=True):
    if numbered:
        label = f"{ROMAN[_h1[0]]}. {text.upper()}"
        _h1[0] += 1
        _h2[0] = 0
    else:
        label = text.upper()
    p = para(align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, before=8, after=4)
    r = p.add_run(label)
    r.font.size = Pt(10)
    r.font.small_caps = True
    p.paragraph_format.keep_with_next = True
    return p


def h2(text):
    label = f"{chr(ord('A') + _h2[0])}. {text}"
    _h2[0] += 1
    p = para(align=WD_ALIGN_PARAGRAPH.LEFT, indent=False, before=6, after=3)
    r = p.add_run(label)
    r.italic = True
    r.font.size = Pt(10)
    p.paragraph_format.keep_with_next = True
    return p


def caption(text, table=False):
    p = para(align=WD_ALIGN_PARAGRAPH.CENTER if table else WD_ALIGN_PARAGRAPH.JUSTIFY,
             indent=False, before=3 if not table else 6, after=6 if not table else 3)
    if table:
        add_runs(p, text, size=8)
        for r in p.runs:
            r.font.small_caps = True
        p.paragraph_format.keep_with_next = True
    else:
        add_runs(p, text, size=8)
    return p


def shade(cell, hex_fill):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_fill)
    tcPr.append(shd)


def table(rows, widths_mm, highlight_rows=()):
    t = doc.add_table(rows=len(rows), cols=len(rows[0]))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    layout = OxmlElement("w:tblLayout")
    layout.set(qn("w:type"), "fixed")
    t._tbl.tblPr.append(layout)
    for j, w in enumerate(widths_mm):
        t.columns[j].width = Mm(w)
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            c = t.cell(i, j)
            c.width = Mm(widths_mm[j])
            p = c.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if j == 0 or i == 0 else WD_ALIGN_PARAGRAPH.LEFT
            add_runs(p, val, size=8, bold=(i == 0))
            p.paragraph_format.keep_with_next = i < len(rows) - 1  # keep table in one piece
            if i in highlight_rows:
                shade(c, "E6F4F1")
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


# ---------- Title block (single column) ----------
sec = doc.sections[0]
page_setup(sec)
set_cols(sec, 1)

p = para(align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, after=10)
r = p.add_run(TITLE)
r.font.size = Pt(24)

auth = doc.add_table(rows=1, cols=len(AUTHORS))
auth.alignment = WD_TABLE_ALIGNMENT.CENTER
for i, (name, role) in enumerate(AUTHORS):
    c = auth.cell(0, i)
    cp = c.paragraphs[0]
    cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rr = cp.add_run(name)
    rr.font.size = Pt(11)
    for line in (role, AFFIL):
        lp = c.add_paragraph()
        lp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        lr = lp.add_run(line)
        lr.font.size = Pt(9)
        lr.italic = line == role
para(after=6)

# ---------- Body (two columns) ----------
body = doc.add_section(WD_SECTION.CONTINUOUS)
page_setup(body)
set_cols(body, 2)

p = para(indent=True, after=4)
r = p.add_run("Abstract—")
r.bold, r.italic, r.font.size = True, True, Pt(9)
add_runs(p, (
    "A processor that keeps instructions and data in one memory with one port must take turns: "
    "when the current instruction reads or writes data, the next instruction fetch has to wait. "
    "This paper presents a small Harvard-style prototype in Verilog in which a 16-word instruction ROM "
    "and a separate 16-word data RAM have independent request paths to an accumulator-based controller. "
    "The controller executes the instruction held in its instruction register while it captures the next "
    "instruction word on the same rising clock edge. A five-instruction demo program "
    "(ADDI, STORE, LOAD, ADDI, HALT) was traced at the bus level: an instruction fetch and a data write occur "
    "together on edge 3, an instruction fetch and a data read occur together on edge 4, and the run ends with "
    "ACC = 6 and RAM[3] = 5. Replaying the same request trace on a modelled single shared port needs "
    "7 memory-service cycles instead of 5 for the split paths, a service rate of 1.00 instead of 1.40 transfers per cycle."
), size=9, bold=True)

p = para(indent=True, after=6)
r = p.add_run("Index Terms—")
r.bold, r.italic, r.font.size = True, True, Pt(9)
add_runs(p, "Harvard architecture, von Neumann architecture, instruction memory, data memory, "
            "structural hazard, Verilog, memory organization", size=9, bold=True)

# ---------- I. Literature Review ----------
h1("Literature Review")
para("In a von Neumann organization, instructions and data live in one memory that is reached through one port. "
     "Every instruction needs at least one fetch, and load and store instructions need a second access to the same "
     "memory. If both requests arrive in the same clock cycle, one of them must wait. Patterson and Hennessy describe "
     "this conflict as a structural hazard: with a single memory, a pipelined processor cannot fetch an instruction in "
     "the same cycle that another instruction accesses data, so practical pipelines provide separate instruction and "
     "data memories or caches [1].")
para("A Harvard organization removes this conflict by giving instructions and data separate memories, each with its "
     "own address, control and data signals. Because the two ports are independent, an instruction fetch and a data "
     "read or write can each be served in the same cycle. The cost is a second memory interface and a fixed split of "
     "storage between code and data.")
para("The Microchip AVR CPU core is a widely used commercial example. Its documentation states that the AVR uses a "
     "Harvard architecture with separate memories and buses for program and data, and that while one instruction is "
     "being executed, the next instruction is pre-fetched from the program memory [2]. This single-level overlap of "
     "execution and fetch is the behavior our prototype reproduces.")
para("The open-source Ibex RISC-V core shows the same separation at the interface level. Its instruction fetch stage "
     "has a dedicated instruction interface, a simplified, read-only version of the data interface, and fills a "
     "small prefetch buffer by fetching instructions linearly [3]. Its load-store unit drives a separate data-side "
     "memory interface with its own request, write-enable and byte-enable signals [4].")
para("This project keeps the essential idea and removes the rest. Compared with AVR and Ibex, the prototype has no "
     "prefetch buffer, no wait states or request handshakes, no byte enables, and no caches or shared lower-level "
     "memory. Each memory answers combinationally within one cycle, and the instruction set has five operations. "
     "These simplifications make every overlapped fetch and data access visible on a single clock edge in simulation.")

# ---------- II. Proposed Solution ----------
h1("Proposed Solution")
h2("Architecture Overview")
para("Fig. 1 shows the prototype. The top-level module `harvard_top` connects three blocks: an instruction ROM "
     "(`instr_rom`), a controller (`controller`) and a data RAM (`data_ram`) [5]. The ROM connects only to the "
     "program counter (PC) and instruction register (IR). The RAM connects only to the accumulator (ACC) and to the "
     "address field of the current instruction. The two paths share the clock but no address, data or enable signals.")

h2("Memories and Addressing")
para("Both memories hold 16 words of 16 bits. Addresses are 4-bit word indices from 0 to 15, so there is no byte "
     "addressing. The same numeric index exists independently in each memory: ROM word 3 and RAM word 3 are "
     "different locations. The ROM is read-only and returns the word at `i_addr` combinationally; unused entries "
     "hold `F000` (HALT). The RAM stores `d_wdata` at the rising edge when `d_we` is high. Its read output is "
     "combinational when `d_re` is high and zero when `d_re` is low. RAM contents start unspecified, so the program "
     "writes a word before reading it [5].")

# Full-width Fig. 1 in a one-column continuous section
fig_sec = doc.add_section(WD_SECTION.CONTINUOUS)
page_setup(fig_sec)
set_cols(fig_sec, 1)
fp = para(align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, before=4)
fp.add_run().add_picture(str(FIG1), width=Mm(165))
caption("Fig. 1. Block diagram of the Harvard prototype. The instruction path (teal) carries `i_req` and the 4-bit PC "
        "to the ROM and returns a 16-bit instruction to the IR. The data path (amber) carries `d_re`, `d_we`, the "
        "4-bit address `ir[11:8]` and ACC write data to the RAM and returns read data to ACC. The caption panel shows "
        "the overlapped edges 3 and 4; the dashed panel is the modelled single-port baseline used in Section II-F.")
body2 = doc.add_section(WD_SECTION.CONTINUOUS)
page_setup(body2)
set_cols(body2, 2)

h2("Controller: PC, IR, ACC and Decode")
para("The controller holds a 4-bit PC, a 16-bit IR with a valid bit (`ir_valid`), a 16-bit ACC and a `halted` flag. "
     "All are updated on the rising edge. Reset is synchronous and active high; it clears these registers and holds "
     "`i_req`, `d_re` and `d_we` low. When `i_req` is high, the IR captures `i_rdata` and the PC increments by one "
     "word, wrapping from 15 to 0.")
para("Decode uses bits [15:12] as the opcode (Table I). LOAD and STORE take the data address from bits [11:8]; ADDI "
     "adds the zero-extended immediate in bits [7:0] to ACC, wrapping at 16 bits. Decode raises `d_re` for LOAD and "
     "`d_we` for STORE, so at most one data enable is active at a time. STORE drives the old ACC value on `d_wdata`. "
     "HALT suppresses the next fetch and sets `halted`; requests stay idle until reset.")

caption("Table I. Instruction Encoding and Demo Program", table=True)
table([
    ["ROM word", "Hex", "Opcode", "Action"],
    ["0", "`3005`", "3 ADDI", "ACC = 0 + 5 = 5"],
    ["1", "`2300`", "2 STORE", "RAM[3] = ACC (5)"],
    ["2", "`1300`", "1 LOAD", "ACC = RAM[3] (5)"],
    ["3", "`3001`", "3 ADDI", "ACC = 5 + 1 = 6"],
    ["4", "`F000`", "F HALT", "Stop; set halted"],
    ["5–15", "`F000`", "F HALT", "Unused fill"],
], [14, 14, 18, 38])
para("Opcode 0 is NOP; all undefined opcodes also behave as NOP. This is a project-specific encoding, not a "
     "standard instruction set.", indent=False)

h2("Overlapping Execution with the Next Fetch")
para("At each rising edge the controller does two things at once. It executes the instruction already held in the "
     "IR, and it captures the next ROM word into the IR. Execution uses the old IR value because all registers are "
     "updated with non-blocking assignments at the same edge. The data request is formed from the old IR "
     "(`d_addr = ir[11:8]`), while the fetch address is the PC. Because these requests go to different memories over "
     "different signals, neither has to wait.")
para("Table II lists the bus-level trace captured from the RTL [6]. Edge 1 is the first rising edge after reset. On "
     "edge 3 the IR holds STORE (`2300`): `d_we` = 1 writes 5 into RAM[3] while `i_addr` = 2 fetches `1300`. On edge "
     "4 the IR holds LOAD (`1300`): `d_re` = 1 returns 5 from RAM[3] while `i_addr` = 3 fetches `3001`. After edge 6 "
     "the controller is halted with ACC = 6 and RAM[3] = 5.")

caption("Table II. Request Trace of the Demo Program", table=True)
table([
    ["Edge", "Fetch (ROM path)", "Data (RAM path)", "Execute (old IR)"],
    ["1", "ROM[0] = 3005", "—", "IR invalid; ACC 0"],
    ["2", "ROM[1] = 2300", "—", "ADDI 5; ACC 5"],
    ["3", "ROM[2] = 1300", "write RAM[3] = 5", "STORE"],
    ["4", "ROM[3] = 3001", "read RAM[3] = 5", "LOAD; ACC 5"],
    ["5", "ROM[4] = F000", "—", "ADDI 1; ACC 6"],
    ["6", "idle", "—", "HALT; halted = 1"],
    ["7+", "idle", "—", "ACC stays 6"],
], [10, 23, 26, 26], highlight_rows=(3, 4))
if FIG2.exists():
    fig2_sec = doc.add_section(WD_SECTION.CONTINUOUS)
    page_setup(fig2_sec)
    set_cols(fig2_sec, 1)
    fig2_p = para(align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, before=4)
    fig2_p.add_run().add_picture(str(FIG2), width=Mm(165))
    caption("Fig. 2. Annotated simulation waveform captured from `tb/harvard_tb.v`. Dual memory path overlap "
            "is confirmed on Edge 3 (Fetch ROM[2] + STORE RAM[3]) and Edge 4 (Fetch ROM[3] + LOAD RAM[3]). "
            "Execution halts cleanly on Edge 6, with all bus requests suppressed in post-halt quiescence.")
    body3 = doc.add_section(WD_SECTION.CONTINUOUS)
    page_setup(body3)
    set_cols(body3, 2)

para("All seven cycle-accurate assertions in `tb/harvard_tb.v` passed cleanly, confirming 5 instruction fetches, "
     "2 data RAM accesses, final ACC = 6, RAM[3] = 5, and halted = 1. In addition, the directed LOAD testbench "
     "(`tb/directed_load_tb.v`) confirmed that LOAD genuinely overwrites the accumulator by demonstrating "
     "ACC transitioning from 7 back to 5.")

h2("Comparison with a Single Shared Port")
para("To measure what the split paths save, the request trace was replayed on a modelled single-port memory [7]. "
     "Code occupies indices 0–15 and data 16–31 of one 32-word memory. The port serves one one-cycle transfer per "
     "cycle. Each edge that issues requests forms a batch, batches are served in trace order, and inside a two-request "
     "batch the data access goes first and the fetch waits one cycle. Cycles are counted from the first transfer to the "
     "last, so the idle HALT edge is not counted.")

caption("Table III. Memory-Service Cycles for the Demo Trace", table=True)
table([
    ["Measure", "Split paths", "One shared port"],
    ["Transfers", "7 (5 fetch + 2 data)", "7"],
    ["Service cycles", "5", "7"],
    ["Extra cycles", "none", "+2 (edges 3, 4)"],
    ["Transfers/cycle", "7/5 = 1.40", "7/7 = 1.00"],
], [24, 30, 30])
para("The two extra cycles come from the two edges where a fetch and a data access coincide. This result is scoped to "
     "this five-instruction workload and this port model. It assumes no arbitration delay, bank conflicts or wait "
     "states, and it is a modelled replay, not a simulation of a separate single-port CPU [7].")

h2("Evidence Status and Limitations")
para("The trace in Table II was verified against `rtl/controller.v`, `rtl/harvard_top.v`, `rtl/instr_rom.v` and "
     "`rtl/data_ram.v` by Puneet's integrated testbench (`tb/harvard_tb.v`). All cycle-by-cycle assertions passed cleanly "
     "under Icarus Verilog.")
para("Synthesis resource utilization and maximum operating frequency: "
     "{{[pending — Neelanshu to share synthesis evidence or status by 16 Nov, 12:00 PM]}}.")
para("The design is intentionally small: 16-word memories, one accumulator, five operations, no branches and no "
     "wait states. Real memories with multi-cycle latency would need a request/valid handshake like Ibex [3], [4].")

# ---------- III. Individual Contributions ----------
h1("Individual Contributions")
contrib = [
    ("Nakul Jaglan",
     "Designed the controller (`rtl/controller.v`) and top-level wiring (`rtl/harvard_top.v`), wrote the prototype "
     "interface (`docs/interface.md`), and leads integration and submission. Commit: "
     f"{REPO}/commit/24451ba."),
    ("Sudeshhna Behera",
     "Wrote this IEEE report (`docs/report/`) and drew the architecture block diagram with its editable source "
     f"(`docs/diagrams/harvard-architecture.svg`). PR: {REPO}/pull/1."),
    ("Neelanshu",
     "Instruction ROM (`rtl/instr_rom.v`), data RAM (`rtl/data_ram.v`), memory tests and synthesis evidence. "
     "{{[Pending: one-line summary of actual work and commit/PR link.]}}"),
    ("Puneet",
     "Designed the integrated cycle-accurate testbench (`tb/harvard_tb.v`) and directed LOAD testbench "
     "(`tb/directed_load_tb.v`), created the automated simulation runner (`scripts/sim.sh`), waveform generator "
     "(`scripts/generate_waveform.py`), verified cycle-by-cycle assertions, and generated waveform evidence "
     f"(`docs/evidence/`). Branch: {REPO}/tree/phase1/puneet."),
    ("Pranav Sehgal",
     "Built the trace-capture testbench and single-port replay script (`baseline/`), documented the shared-port "
     "comparison (`docs/baseline.md`), and prepared the demo video script and page (`docs/demo/`). Commit: "
     f"{REPO}/commit/2a7c09c."),
]
for name, text in contrib:
    p = para(indent=False, after=3, align=WD_ALIGN_PARAGRAPH.LEFT)
    add_runs(p, f"**{name}:** " + text)

# ---------- References ----------
h1("References", numbered=False)
refs = [
    "D. A. Patterson and J. L. Hennessy, Computer Organization and Design RISC-V Edition: The Hardware/Software "
    "Interface, 2nd ed. Cambridge, MA, USA: Morgan Kaufmann/Elsevier, 2020. [Online]. Available: "
    "https://shop.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-820331-6",
    "Microchip Technology Inc., “AVR CPU core: Overview,” in ATmega48PB/88PB/168PB Data Sheet, Sec. 12.1. "
    "[Online]. Available: https://onlinedocs.microchip.com/oxy/GUID-EC8D3BAB-0B5E-454F-AB6E-6A7C91C6F103-en-US-3/"
    "GUID-3796F3EA-72E7-4987-9D50-8805139A5F2E.html (accessed Nov. 15, 2026).",
    "lowRISC, “Instruction fetch,” Ibex Reference Guide. [Online]. Available: "
    "https://ibex-core.readthedocs.io/en/latest/03_reference/instruction_fetch.html (accessed Nov. 15, 2026).",
    "lowRISC, “Load-store unit,” Ibex Reference Guide. [Online]. Available: "
    "https://ibex-core.readthedocs.io/en/latest/03_reference/load_store_unit.html (accessed Nov. 15, 2026).",
    f"N. Jaglan, “Prototype interface,” MCA Team 67 repository, docs/interface.md, Nov. 2026. [Online]. "
    f"Available: {REPO}/blob/main/docs/interface.md",
    f"P. Sehgal, “Harvard request trace,” MCA Team 67 repository, baseline/harvard_trace.csv and "
    f"baseline/trace_capture_tb.v, Nov. 2026. [Online]. Available: {REPO}/tree/main/baseline",
    f"P. Sehgal, “Shared-port baseline,” MCA Team 67 repository, docs/baseline.md, Nov. 2026. [Online]. "
    f"Available: {REPO}/blob/main/docs/baseline.md",
]
for i, ref in enumerate(refs, 1):
    p = para(indent=False, after=2, align=WD_ALIGN_PARAGRAPH.LEFT)
    p.paragraph_format.left_indent = Mm(6)
    p.paragraph_format.first_line_indent = Mm(-6)
    add_runs(p, f"[{i}]\t{ref}", size=8)

doc.core_properties.title = TITLE
doc.core_properties.author = "MCA Team 67"
OUT.parent.mkdir(parents=True, exist_ok=True)
doc.save(OUT)
print(f"Wrote {OUT.relative_to(ROOT)}")
