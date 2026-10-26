# FAQ

Short answers first. Setup is in [setup.md](setup.md), problems in [troubleshooting.md](troubleshooting.md).

## What does this patch do?

It changes one line in squeekboard's `src/panel.c` so the on-screen keyboard asks the compositor for the layer-shell `OVERLAY` layer instead of `TOP`. That puts the keyboard above fullscreen windows, so a fullscreen kiosk app no longer hides it.

## Why is squeekboard invisible in my fullscreen kiosk?

Squeekboard requests the `TOP` layer, and wlroots-based compositors such as labwc draw fullscreen windows above `TOP`. The keyboard starts and receives input events, but it is drawn behind the page. Moving it to `OVERLAY` fixes that. [How it works](how-it-works.md) has the diagram.

## Can I fix this in labwc configuration instead?

No compositor setting is known to do it. The layer-shell protocol cannot express "hide the panel but not the keyboard", and the labwc issue linked from the README was closed without a new option.

## Does it work on Raspberry Pi 4 or other compositors?

Unverified. The author tested a Pi 5 with labwc and TouchKio (see the [tested table](../README.md#-tested-on)). Any wlroots compositor with the same stacking should behave the same, but that is untested. Reports are welcome, see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Does it work with Chromium or Electron apps?

Yes for the tested setup, with one extra step: start the app with `--enable-wayland-ime`, or the keyboard never opens.

## Is it safe to use on a phone or desktop?

Not recommended. On the `OVERLAY` layer the keyboard can draw above a lock screen. Use stock squeekboard on devices that are not kiosks.

## Will `apt upgrade` overwrite my patched squeekboard?

Yes, unless you hold the package: `sudo apt-mark hold squeekboard`. `apt-mark unhold` reverses it.

## How long does the build take?

About 15 to 30 minutes on a Pi 5, longer on a Pi 4 (the figures in `build.sh`).

## Which squeekboard version does it target?

`build.sh` defaults to `1.43.1-1+rpt1`, the Raspberry Pi OS Trixie package. CI also checks the patch against the current upstream and Raspberry Pi fork `src/panel.c` every week.

## Why is this a patch and not a pull request?

The change is unconditional, which suits kiosks and not other devices. An upstream-shaped fix would be a runtime option. The README links the open discussions.

## Is the built package signed?

No. `build.sh` builds with `-us -uc`, so the `.deb` is unsigned. Install only packages you built yourself.

## What license is it under?

GPLv3, the same as squeekboard, because this repo distributes a patch against its source.
