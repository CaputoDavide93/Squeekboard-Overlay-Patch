#!/usr/bin/env python3
"""Doc checks: no em or en dashes in public text, every docs/*.md is indexed."""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
FILES = [ROOT / n for n in ("README.md", "CONTRIBUTING.md", "SECURITY.md", "llms.txt")]
FILES += sorted((ROOT / "docs").glob("*.md"))
bad = 0
for f in FILES:
    for n, line in enumerate(f.read_text().splitlines(), 1):
        if "—" in line or "–" in line:
            print(f"{f.relative_to(ROOT)}:{n}: em or en dash")
            bad += 1
index = (ROOT / "docs" / "README.md").read_text()
for f in sorted((ROOT / "docs").glob("*.md")):
    if f.name != "README.md" and f"({f.name})" not in index:
        print(f"docs/README.md does not link {f.name}")
        bad += 1
print("docs ok" if not bad else f"{bad} problem(s)")
sys.exit(1 if bad else 0)
