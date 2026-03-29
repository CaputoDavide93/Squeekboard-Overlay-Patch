#!/usr/bin/env bash
# Build squeekboard with the OVERLAY layer patch
# Run this on a Raspberry Pi (arm64) with Debian Trixie / Raspberry Pi OS (Bookworm+)
set -euo pipefail

SQUEEKBOARD_VERSION="${1:-1.43.1-1+rpt1}"
WORK_DIR="${2:-$(mktemp -d)}"

echo "==> Working in $WORK_DIR"
cd "$WORK_DIR"

# ── 1. Install build dependencies ──
echo "==> Installing build dependencies..."
sudo apt-get update
sudo apt-get build-dep -y squeekboard
sudo apt-get install -y devscripts dpkg-dev

# ── 2. Fetch source ──
echo "==> Fetching squeekboard source ($SQUEEKBOARD_VERSION)..."
apt-get source "squeekboard=$SQUEEKBOARD_VERSION"
SRCDIR=$(find . -maxdepth 1 -type d -name 'squeekboard-*' | head -1)
echo "==> Source directory: $SRCDIR"
cd "$SRCDIR"

# ── 3. Apply the patch ──
echo "==> Applying OVERLAY layer patch..."
PANEL_C="src/panel.c"
if ! grep -q 'ZWLR_LAYER_SHELL_V1_LAYER_TOP' "$PANEL_C"; then
    echo "ERROR: Could not find LAYER_TOP in $PANEL_C — source may have changed."
    exit 1
fi

sed -i 's/ZWLR_LAYER_SHELL_V1_LAYER_TOP/ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY/g' "$PANEL_C"
echo "==> Patched: $(grep 'ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY' "$PANEL_C")"

# ── 4. Build ──
echo "==> Building (this takes ~15-30 min on a Pi 5, longer on Pi 4)..."
dpkg-buildpackage -us -uc -b

# ── 5. Install ──
echo "==> Build complete. Install the .deb package:"
cd "$WORK_DIR"
DEB=$(find . -maxdepth 1 -name 'squeekboard_*.deb' | head -1)
echo ""
echo "  sudo dpkg -i $DEB"
echo ""
echo "Then restart squeekboard:"
echo "  systemctl --user restart squeekboard"
echo ""
echo "==> Done!"
