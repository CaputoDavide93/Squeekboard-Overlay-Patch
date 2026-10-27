# How it works

## The stacking problem

Wayland compositors built on wlroots, labwc included, draw layer-shell surfaces in four layers, from back to front: `BACKGROUND` (0), `BOTTOM` (1), `TOP` (2) and `OVERLAY` (3). A fullscreen window sits above `TOP` and below `OVERLAY`.

Squeekboard asks for `TOP`. On a phone that is right: the keyboard sits under system overlays. In a fullscreen kiosk it means the keyboard is initialised, receives input-method events, logs no errors, and is drawn behind the page.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/layers-dark.svg">
  <img src="assets/layers-light.svg" width="100%" alt="Layer-shell stacking from top to bottom is OVERLAY, the fullscreen kiosk app, TOP, then BOTTOM and BACKGROUND, so stock Squeekboard on TOP is hidden and the patch moves it to OVERLAY.">
</picture>

The layer-shell protocol has no way to say "hide the panel but not the keyboard", and the labwc issue linked from the README was closed without adding a compositor option. So the change has to happen in squeekboard.

## The patch

One line in `src/panel.c`:

```diff
-            "layer", ZWLR_LAYER_SHELL_V1_LAYER_TOP,
+            "layer", ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
```

`overlay-layer.patch` carries a short description and this one hunk, applied with `patch -p1` from the root of the source tree.

## What `build.sh` does

1. Checks that `deb-src` entries exist and stops with the fix if not.
2. Installs build dependencies (`sudo apt-get build-dep squeekboard`, plus `devscripts` and `dpkg-dev`).
3. Fetches the source of the pinned version with `apt-get source`.
4. Dry-runs the patch with `--forward`, so a reversed or already-applied patch is refused, then applies it.
5. Greps `src/panel.c`: it must mention `OVERLAY` and no longer mention `TOP`.
6. Builds an unsigned package with `dpkg-buildpackage -us -uc -b` and prints the `dpkg -i` command.

## The input-method chain

A visible keyboard is only half of typing. All of these must hold:

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/architecture-dark.svg">
  <img src="assets/architecture-light.svg" width="100%" alt="A tap in the Electron kiosk enables text-input on labwc, which activates Squeekboard; the patched Squeekboard draws on the OVERLAY layer above the fullscreen app, and its key taps come back to the app as committed text.">
</picture>

- The app opens a text-input connection (Electron and Chromium need `--enable-wayland-ime`).
- labwc activates squeekboard through the input-method protocol.
- Squeekboard draws on `OVERLAY` (this patch).
- Key taps return to the app as committed text.

## Trade-off

`OVERLAY` can draw above a compositor's lock screen. On a locked-down kiosk that rarely matters. On a general-purpose desktop or phone, keep stock squeekboard. See [SECURITY.md](../SECURITY.md).

## Why not a pull request upstream

The patch is unconditional, which is wrong for devices that are not kiosks. The upstream-shaped fix is a runtime option that kiosk builds switch on. The README links the open issues where this is discussed.
