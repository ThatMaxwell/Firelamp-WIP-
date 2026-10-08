# Firelamp OS ISO

The bootable live image of Firelamp OS, built with [archiso](https://wiki.archlinux.org/title/Archiso)
from a profile based on Arch's `releng`.

## What's in it

| Layer | Choice | Why |
| --- | --- | --- |
| Base | Arch Linux, `linux` kernel, systemd | rolling, current Qt and Mesa |
| Compositor | [labwc](https://labwc.github.io/) (wlroots) | small stacking WM with layer-shell, so a QML top bar and dock can sit on screen edges while apps get normal floating windows |
| Fallback compositor | cage | kiosk mode: boot with `firelamp.compositor=cage` to run the shell full screen |
| UI toolkit | Qt 6 / QML (`qt6-declarative`, `qt6-wayland`, `layer-shell-qt`, `qt6-svg`, `qt6-5compat`, `qt6-shadertools`) | the desktop shell is QML |
| UI tree for the AI | AT-SPI2 (`at-spi2-core`, `python-atspi`) | live, labelled tree of every window and control, no screenshots |
| AI input | `ydotool`, `wtype` | synthetic pointer and keyboard for the fire cursor |
| VM guests | VirtualBox, QEMU, VMware tools | VirtualBox is the dev target |

The live user is `firelamp` (no password, passwordless sudo). It logs in on tty1 and
`firelamp-session` starts labwc, which runs the shell.

## The shell contract

`/usr/local/bin/firelamp-shell` picks the first of:

1. `$FIRELAMP_SHELL_CMD`, any command (handy while developing)
2. `/usr/lib/firelamp/shell/firelamp-shell`, a compiled shell binary
3. `/usr/share/firelamp/shell/Main.qml`, run with Qt's `qml` tool
4. the built-in placeholder screen

`build.sh` copies the repo's `shell/` folder to `/usr/share/firelamp/shell`, so a
`shell/Main.qml` in the repo is all it takes to ship the desktop. Extra Arch packages
the shell needs go in `shell/packages.x86_64`, one per line.

Qt apps in the session run with `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1`, so they show up
on the AT-SPI2 bus. `firelamp-a11y-probe` prints the tree the AI sees.

## Build

On any Linux machine with Docker:

```sh
sudo iso/build.sh --docker
```

On Arch with `archiso` installed: `sudo iso/build.sh`. The ISO lands in `iso/out/`.

GitHub Actions (`.github/workflows/iso.yml`) builds the ISO on every change to
`iso/` or `shell/`, boots it in QEMU (BIOS and UEFI), and uploads the ISO,
desktop screenshots and a boot GIF as run artifacts.

## Test

```sh
python3 iso/test-boot.py iso/out/firelamp-*.iso --out boot-test
```

boots the ISO headless in QEMU, waits for the desktop to report in on the serial
port (compositor, shell and AT-SPI2 status), and saves `desktop.png` and `boot.gif`.

### VirtualBox

New VM, type Linux / Arch Linux (64-bit), 4 GB RAM, Graphics Controller **VMSVGA**,
attach the ISO as the optical drive. Enable EFI if you want to test UEFI boot.
Enabling 3D acceleration gives hardware rendering; without it the session falls back
to software rendering automatically.

## Boot options

- **Firelamp OS**: the desktop
- **console only**: boots to a shell (`firelamp.nosession`)
- **speech**: speakup screen reader
- add `firelamp.compositor=cage` to the kernel line for kiosk mode
