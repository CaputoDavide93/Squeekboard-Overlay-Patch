# Contributing

## Report a setup that works or fails

Hardware and software outside the [tested table](README.md#-tested-on) is the most useful thing you can send. Open an issue with:

- What you tried and what you saw: keyboard visible or hidden, typing worked or not.
- The output of these commands:

  ```bash
  cat /proc/device-tree/model; uname -m
  grep PRETTY_NAME /etc/os-release
  labwc --version
  dpkg -l squeekboard
  apt-mark showhold
  systemctl --user status squeekboard --no-pager
  journalctl --user -u squeekboard -n 50 --no-pager
  ```

- The kiosk app and how it is started (the command line, with any URL replaced by an example).

Remove addresses, hostnames and tokens before pasting.

## Send a change

1. Branch from `main`.
2. Run `make check`, and `make patch-check` if you touched the patch.
3. Use a conventional commit message (`fix:`, `docs:`, `ci:`).
4. Open a pull request. Docs must stay true of the code: every command shown has to run, and unverified claims are marked as such.

Report vulnerabilities privately, see [SECURITY.md](SECURITY.md).
