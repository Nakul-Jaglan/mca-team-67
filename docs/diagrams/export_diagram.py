"""Export the editable SVG block diagram to report-ready PNG and PDF files.

Usage (from the repository root):
    pip install cairosvg
    python3 docs/diagrams/export_diagram.py
"""
from pathlib import Path

import cairosvg

HERE = Path(__file__).resolve().parent
SRC = HERE / "harvard-architecture.svg"

cairosvg.svg2png(url=str(SRC), write_to=str(HERE / "harvard-architecture.png"), scale=3)
cairosvg.svg2pdf(url=str(SRC), write_to=str(HERE / "harvard-architecture.pdf"))
print("Wrote harvard-architecture.png and harvard-architecture.pdf")
