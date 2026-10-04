#!/usr/bin/env bash
# Build squeekboard with the OVERLAY layer patch
# Run this on a Raspberry Pi (arm64) with Raspberry Pi OS Trixie (Debian 13).
# The default version, 1.43.1-1+rpt1, is the Raspberry Pi OS Trixie package.
set -euo pipefail

SQUEEKBOARD_VERSION="${1:-1.43.1-1+rpt1}"
WORK_DIR="${2:-$(mktemp -d)}"

# Resolve the patch path before changing directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/overlay-layer.patch"
if [ ! -r "$PATCH_FILE" ]; then
    echo "ERROR: $PATCH_FILE not found — run build.sh from a full clone of the repo." >&2
    exit 1
fi

echo "==> Working in $WORK_DIR"
cd "$WORK_DIR"

# ── 1. Verify APT source repositories are enabled ──
# Both `apt-get build-dep` and `apt-get source` need deb-src entries, which are
# NOT enabled by default on Debian / Raspberry Pi OS. Fail early with a fix.
echo "==> Checking that APT source repositories (deb-src) are enabled..."
if ! { grep -qsE '^[[:space:]]*deb-src[[:space:]]' /etc/apt/sources.list \
    || grep -qsRE '^[[:space:]]*deb-src[[:space:]]' /etc/apt/sources.list.d/ \
    || grep -qsRE '^[[:space:]]*Types:.*deb-src' /etc/apt/sources.list.d/; }; then
    cat >&2 <<'MSG'
ERROR: No APT source repositories (deb-src) are enabled, so the squeekboard
       source cannot be fetched. Enable them, then re-run this script.

  Raspberry Pi OS Trixie / Debian 13+ (deb822 format):
    sudo sed -i 's/^Types: deb$/Types: deb deb-src/' \
        /etc/apt/sources.list.d/debian.sources \
        /etc/apt/sources.list.d/raspi.sources

  Older releases (one-line format) — uncomment or add the deb-src lines:
    sudo nano /etc/apt/sources.list

  Then:
    sudo apt-get update
MSG
    exit 1
fi

# ── 2. Install build dependencies ──
echo "==> Installing build dependencies..."
sudo apt-get update
sudo apt-get build-dep -y squeekboard
sudo apt-get install -y devscripts dpkg-dev

# ── 3. Fetch source ──
echo "==> Fetching squeekboard source ($SQUEEKBOARD_VERSION)..."
apt-get source "squeekboard=$SQUEEKBOARD_VERSION"
SRCDIR=$(find . -maxdepth 1 -type d -name 'squeekboard-*' | head -1)
echo "==> Source directory: $SRCDIR"
cd "$SRCDIR"

# ── 4. Apply the patch ──
echo "==> Applying OVERLAY layer patch ($PATCH_FILE)..."
PANEL_C="src/panel.c"
# --forward refuses a reversed or already-applied patch instead of undoing it.
if ! patch -p1 --forward --dry-run < "$PATCH_FILE" > /dev/null; then
    echo "ERROR: overlay-layer.patch does not apply to $SRCDIR — source changed, or it is already patched." >&2
    exit 1
fi
patch -p1 --forward < "$PATCH_FILE"
if grep -q 'ZWLR_LAYER_SHELL_V1_LAYER_TOP' "$PANEL_C" \
    || ! grep -q 'ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY' "$PANEL_C"; then
    echo "ERROR: $PANEL_C does not select the OVERLAY layer after patching." >&2
    exit 1
fi
echo "==> Patched: $(grep 'ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY' "$PANEL_C")"

# ── 5. Build ──
echo "==> Building (this takes ~15-30 min on a Pi 5, longer on Pi 4)..."
dpkg-buildpackage -us -uc -b

# ── 6. Install ──
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
