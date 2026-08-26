# 🔒 Security Policy

## Reporting a vulnerability

Please report vulnerabilities privately via
[GitHub Security Advisories](https://github.com/CaputoDavide93/Squeekboard-Overlay-Patch/security/advisories/new)
rather than opening a public issue. You should get a response within a week.

## What this repo contains

A source patch and a build script. There is no service, no network listener, and no
runtime component — nothing here processes personal data, and the repo reads no
credentials, tokens, or environment secrets.

## What to be aware of

- **`build.sh` runs `sudo`.** It installs build dependencies and, if source repositories
  are not enabled, tells you to edit `/etc/apt/sources.list*`. Read it before running it,
  as with any script that asks for elevated privileges.
- **The patch widens the keyboard's stacking order.** Moving squeekboard from the `TOP`
  layer to `OVERLAY` is deliberate — it is what makes the keyboard visible over a
  fullscreen kiosk app. Be aware of the consequence: an `OVERLAY` surface also draws above
  a compositor's screen-lock surface on compositors that place the lock screen below
  `OVERLAY`. On a locked-down kiosk that is usually irrelevant; on a general-purpose
  desktop or phone, prefer the unpatched `TOP` layer.
- **Packages you build are unsigned.** `dpkg-buildpackage -us -uc` produces an unsigned
  `.deb`. Install only packages you built yourself from source you trust.
- **Verify before you build.** The patch targets upstream squeekboard source fetched by
  `apt-get source`; confirm you are building the version you intend.

## Supported versions

Only the latest commit on `main` is supported.
