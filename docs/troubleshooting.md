# Troubleshooting

Find your symptom, then follow the checks in order.

## The keyboard is not visible after installing

Check that the running binary is the patched one. A failed `dpkg -i`, or an `apt upgrade` afterwards, restores the stock package.

```bash
dpkg -l squeekboard
apt-mark showhold
systemctl --user restart squeekboard
```

The version should be the one you built, and `squeekboard` should appear in the hold list (`sudo apt-mark hold squeekboard` if not). If it is patched and still hidden, the compositor may place another surface above `OVERLAY`. A fullscreen layer-shell surface on `OVERLAY` ties with the keyboard instead of sitting below it.

## The keyboard appears, but typing does nothing

The keyboard is drawing, but no text-input connection exists. Check in order:

1. The app was started with `--enable-wayland-ime`.
2. `GTK_IM_MODULE=wayland` and `QT_IM_MODULE=wayland` are in the compositor environment, not only your shell profile.
3. `systemctl --user status squeekboard` shows it running under the same `WAYLAND_DISPLAY` as the compositor.

## The keyboard never opens when I tap a field

The app is not announcing a text-input. For Electron and Chromium apps, add `--enable-wayland-ime` and restart the app. Without it the keyboard stays closed, patched or not.

## `patch: **** malformed patch` or hunk failures

Apply from the root of the extracted source tree. The patch uses `a/src/panel.c` paths and expects `-p1`.

```bash
cd squeekboard-*/
patch -p1 < overlay-layer.patch
```

If the hunk genuinely fails, upstream changed `src/panel.c`. Check the [CI status](https://github.com/CaputoDavide93/Squeekboard-Overlay-Patch/actions/workflows/ci.yml); a red weekly run means the patch needs regenerating. Please open an issue.

## `build.sh` says the patch does not apply, or is already patched

`build.sh` refuses a reversed or already-applied patch. Use a fresh work directory (the default is a new temporary one) and a squeekboard version whose `src/panel.c` matches the patch.

## `apt-get source` or `build-dep` fails

Source repositories are off by default on Debian and Raspberry Pi OS. `build.sh` checks and prints the fix. By hand:

```bash
# Raspberry Pi OS Trixie / Debian 13+ (deb822 format)
sudo sed -i 's/^Types: deb$/Types: deb deb-src/' \
    /etc/apt/sources.list.d/debian.sources \
    /etc/apt/sources.list.d/raspi.sources

# Older releases: uncomment the deb-src lines in /etc/apt/sources.list

sudo apt-get update
```

## The keyboard covers my lock screen

That is the trade-off of the `OVERLAY` layer. Use stock squeekboard on devices that are not kiosks. See [SECURITY.md](../SECURITY.md).

## Still stuck

Open an [issue](https://github.com/CaputoDavide93/Squeekboard-Overlay-Patch/issues) with the diagnostics listed in [CONTRIBUTING.md](../CONTRIBUTING.md).
