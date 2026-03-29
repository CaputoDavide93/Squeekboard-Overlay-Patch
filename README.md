# squeekboard overlay-layer patch

A one-line patch for [squeekboard](https://gitlab.gnome.org/World/Phosh/squeekboard) that makes the on-screen keyboard render **above fullscreen Wayland applications**.

## The problem

On Raspberry Pi kiosk setups running a fullscreen Electron/Chromium app under **labwc** (or any wlroots-based compositor), squeekboard is invisible — it renders behind the fullscreen window.

This happens because of the Wayland layer-shell stacking order:

```
OVERLAY      ← keyboard needs to be here
─────────────
FULLSCREEN   ← kiosk app (blocks everything below)
─────────────
TOP          ← where squeekboard renders by default
─────────────
BOTTOM / BACKGROUND
```

Squeekboard uses `ZWLR_LAYER_SHELL_V1_LAYER_TOP`, which sits below fullscreen surfaces. The keyboard initialises, receives input-method events, and logs no errors — but is simply not visible.

## The fix

Change one constant in [`src/panel.c`](https://gitlab.gnome.org/World/Phosh/squeekboard/-/blob/master/src/panel.c):

```diff
-    "layer", ZWLR_LAYER_SHELL_V1_LAYER_TOP,
+    "layer", ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
```

This moves squeekboard to the `OVERLAY` layer, which renders above everything — including fullscreen surfaces.

## Quick start

### Option A: Automated build (Raspberry Pi)

```bash
git clone https://github.com/CaputoDavide93/squeekboard-overlay-patch.git
cd squeekboard-overlay-patch
chmod +x build.sh
./build.sh
```

This fetches the squeekboard source, applies the patch, and builds a `.deb` package. It takes ~15-30 minutes on a Pi 5 (longer on a Pi 4).

### Option B: Manual patch

```bash
# Get the source
apt-get source squeekboard
cd squeekboard-*/

# Apply the patch
patch -p1 < /path/to/overlay-layer.patch

# Build
dpkg-buildpackage -us -uc -b

# Install
sudo dpkg -i ../squeekboard_*.deb
```

### Option C: Binary patch (no rebuild)

If you'd rather not compile, you can patch the installed binary directly:

```bash
# Backup the original
sudo cp /usr/bin/squeekboard /usr/bin/squeekboard.bak

# Patch in place (the constant name appears as a string in the enum usage)
sudo sed -i 's/ZWLR_LAYER_SHELL_V1_LAYER_TOP/ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY/' /usr/bin/squeekboard

# Restart
systemctl --user restart squeekboard
```

> **Note:** Option C is fragile — it depends on the string representation in the binary and may not work on all versions. The source rebuild (Options A/B) is recommended.

## Full kiosk setup

For the on-screen keyboard to work with a fullscreen Electron app, you also need:

### 1. Wayland input-method protocol

Set these environment variables in your compositor config (e.g. labwc `environment`):

```
GTK_IM_MODULE=wayland
QT_IM_MODULE=wayland
```

### 2. Electron/Chromium IME flag

Launch your Electron app with:

```
--enable-wayland-ime
```

For example, with [TouchKio](https://github.com/nickvdp/touchkio):

```ini
# ~/.config/systemd/user/touchkio.service
[Service]
ExecStart=/usr/bin/touchkio --enable-wayland-ime --web-url=http://your-ha:8123/ ...
```

### 3. Squeekboard systemd service

```ini
# ~/.config/systemd/user/squeekboard.service
[Unit]
Description=squeekboard on-screen keyboard
After=touchkio.service
Wants=touchkio.service

[Service]
Type=simple
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/squeekboard
Restart=on-failure
RestartSec=5
Environment=XDG_RUNTIME_DIR=/run/user/%U
Environment=WAYLAND_DISPLAY=wayland-0
Environment=GDK_BACKEND=wayland
Environment=GTK_THEME=Adwaita:dark

[Install]
WantedBy=default.target
```

Enable and start:

```bash
systemctl --user enable squeekboard.service
systemctl --user start squeekboard.service
```

> The 3-second delay (`ExecStartPre=/bin/sleep 3`) ensures the kiosk app has fully started before squeekboard initialises.

## Tested on

| Component | Version |
|---|---|
| Raspberry Pi | 5 (arm64) |
| OS | Debian Trixie (Raspberry Pi OS) |
| Compositor | labwc 0.9.x |
| squeekboard | 1.43.1-1+rpt1 |
| Kiosk app | TouchKio (Electron) |
| Home Assistant | 2026.2.x |

## Why not upstream?

This change makes squeekboard always render on the overlay layer, which is correct for fullscreen kiosk use cases. On a standard phone or desktop setup, `LAYER_TOP` is the right choice — the keyboard should not cover system overlays.

An ideal upstream fix would be a command-line flag or config option (e.g. `--layer=overlay`). Relevant issues:

- [labwc/labwc#2926](https://github.com/labwc/labwc/issues/2926) — Squeekboard not visible over fullscreen Chromium
- [labwc/labwc#1873](https://github.com/labwc/labwc/issues/1873) — Virtual keyboards discussion
- [raspberrypi-ui/squeekboard#13](https://github.com/raspberrypi-ui/squeekboard/issues/13) — Squeekboard fullscreen fix

## License

The patch itself is trivial and released under [CC0](https://creativecommons.org/publicdomain/zero/1.0/). Squeekboard is licensed under [GPLv3](https://gitlab.gnome.org/World/Phosh/squeekboard/-/blob/master/COPYING).
