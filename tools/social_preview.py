#!/usr/bin/env python3
"""Render docs/assets/social-preview.png (1280x640) with headless Google Chrome.

The PNG is re-saved through Pillow so it carries no metadata. Not part of CI:
Chrome output can differ by version. Upload the result by hand in the repo's
settings (Social preview).
"""
import pathlib
import subprocess
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/assets/social-preview.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ICON = (ROOT / "docs/assets/brand/icon.svg").read_text()
CHIPS = ["Raspberry Pi", "labwc", "Wayland", "GPLv3"]
HTML = f"""<body style="margin:0;width:1280px;height:640px;background:#0f1c33;color:#f1f4f9;
font-family:system-ui,-apple-system,'Segoe UI',sans-serif;display:flex;align-items:center;gap:56px;padding:0 90px;box-sizing:border-box">
<div style="width:260px;height:260px;flex:none">{ICON.replace('<svg ', '<svg width="260" height="260" ')}</div>
<div><div style="font-size:64px;font-weight:700;line-height:1.1">Squeekboard<br>Overlay-Layer Patch</div>
<div style="font-size:30px;color:#b4c0d8;margin-top:22px;line-height:1.3">Keep the on-screen keyboard above<br>fullscreen apps on Raspberry Pi kiosks</div>
<div style="margin-top:34px;display:flex;gap:14px">{''.join(f'<span style="border:2px solid #4c7ef3;color:#cfe0ff;border-radius:999px;padding:8px 20px;font-size:24px">{c}</span>' for c in CHIPS)}</div></div></body>"""

with tempfile.TemporaryDirectory() as d:
    page, shot = pathlib.Path(d) / "card.html", pathlib.Path(d) / "card.png"
    page.write_text(HTML)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    f"--screenshot={shot}", "--window-size=1280,640", f"file://{page}"],
                   check=True, capture_output=True)
    img = Image.open(shot).convert("RGB")
    assert img.size == (1280, 640), img.size
    img.save(OUT, optimize=True)  # convert() dropped any text chunks
print(f"wrote {OUT.relative_to(ROOT)}")
