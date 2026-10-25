# Setup

Install the patched squeekboard on a Raspberry Pi kiosk, then wire up the three pieces that make typing work. There is no graphical setup, so there are no screenshots; every step is a command.

## Before you start

- A Raspberry Pi running Raspberry Pi OS (Debian Trixie, arm64) with the labwc compositor and a fullscreen kiosk app.
- `sudo` rights, and 15 to 30 minutes for the build on a Pi 5 (longer on a Pi 4).
- The Debian source repositories (`deb-src`) enabled. `build.sh` checks this and prints the fix if they are missing.
- A kiosk app that speaks the Wayland text-input protocol. Electron and Chromium apps need the `--enable-wayland-ime` flag.

## 1. Build the patched package

```bash
git clone https://github.com/CaputoDavide93/Squeekboard-Overlay-Patch.git
cd Squeekboard-Overlay-Patch
./build.sh
```

`build.sh` takes two optional arguments, `[SQUEEKBOARD_VERSION] [WORK_DIR]`. The defaults are `1.43.1-1+rpt1` (the Raspberry Pi OS Trixie package) and a fresh temporary directory.

```bash
./build.sh 1.43.1-1+rpt1 ~/build
```

The script checks `deb-src`, installs build dependencies with `sudo apt-get build-dep`, fetches the source, applies [`overlay-layer.patch`](../overlay-layer.patch), checks that `src/panel.c` now selects `OVERLAY`, builds an unsigned `.deb`, and prints the install command.

### Or patch by hand

```bash
apt-get source squeekboard
cd squeekboard-*/
patch -p1 < /path/to/overlay-layer.patch
dpkg-buildpackage -us -uc -b
```

## 2. Install and hold the package

```bash
sudo dpkg -i /path/printed/by/build.sh/squeekboard_*.deb
sudo apt-mark hold squeekboard
```

The hold stops a later `apt upgrade` from replacing your build with the stock package.

## 3. Set the input-method environment

In the compositor's environment file (for labwc, `~/.config/labwc/environment`):

```bash
GTK_IM_MODULE=wayland
QT_IM_MODULE=wayland
```

## 4. Start the kiosk app with the IME flag

Chromium-based apps only use the Wayland text-input protocol when told to. Without the flag the keyboard never opens, patched or not.

```ini
# ~/.config/systemd/user/touchkio.service
[Service]
ExecStart=/usr/bin/touchkio --enable-wayland-ime --web-url=https://kiosk.example.com/
```

The example uses [TouchKio](https://github.com/leukipp/touchkio); any Electron or Chromium kiosk takes the same flag.

## 5. Run squeekboard as a user service

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

```bash
systemctl --user daemon-reload
systemctl --user enable --now squeekboard.service
```

The three-second sleep lets the compositor and kiosk app settle before squeekboard binds its layer surface.

## 6. Check it

Tap a text field in the kiosk app. The keyboard should slide up over the fullscreen page, and keys should type into the field. If not, see [troubleshooting](troubleshooting.md).

## Going back to stock squeekboard

```bash
sudo apt-mark unhold squeekboard
sudo apt-get install --reinstall squeekboard
systemctl --user restart squeekboard
```

## What was verified

| Step | Status |
|---|---|
| Patch applies to upstream and to the Raspberry Pi fork `src/panel.c` | Checked by CI on every push and weekly |
| `build.sh` passes `shellcheck` | Checked by CI |
| `build.sh` end to end, keyboard visible over the kiosk | Run by the author on the hardware in the [tested table](../README.md#-tested-on). CI does not run it |
| Other Pi models, other compositors, other kiosk apps | Unverified |
