# Firelamp OS ISO

The bootable live image of Firelamp OS, built with [archiso](https://wiki.archlinux.org/title/Archiso)
from a profile based on Arch's `releng`.

## What's in it

| Layer | Choice | Why |
| --- | --- | --- |
| Base | Arch Linux + the [CachyOS](https://cachyos.org) repo, `linux-cachyos` kernel, `cachyos-settings` | performance-tuned kernel and system defaults |
| Desktop | KDE Plasma 6 on Wayland, SDDM autologin | the default desktop, with the Firelamp shell on top |
| Other desktops | one-click installs (`firelamp-desktops`) | GNOME, COSMIC, Xfce, Hyprland, niri, Sway; nothing extra is preinstalled |
| UI toolkit | Qt 6 / QML, `layer-shell-qt` | the Firelamp shell is QML |
| UI tree for the AI | AT-SPI2 (`at-spi2-core`, `python-atspi`) | live, labelled tree of every window and control, no screenshots |
| AI input | `ydotool`, `wtype` | synthetic pointer and keyboard for the fire cursor |
| VM guests | VirtualBox, QEMU, VMware tools | VirtualBox is the dev target |

Package sets live in `packages/`, one file per set, and `build.sh` adds them all:
`10-desktop-plasma`, `20-basic-tools` (Firefox, Dolphin, Konsole, Kate, archive and CLI basics),
`30-dev-tools` (base-devel, git, gh, clang, cmake, Python, Node, Go, rustup, VS Code OSS, Podman),
`40-ricing` (Kvantum, qt6ct, nwg-look, Nerd Fonts, Starship, kitty, cava, btop) and
`50-ai-tools` (Ollama and a small Python stack). Add a package by adding a line.

The CachyOS repo is the generic x86-64 one, so the ISO boots on any 64-bit PC.

The live user is `firelamp` (no password, passwordless sudo). SDDM logs it into Plasma,
and `/etc/xdg/autostart/firelamp-session-start.desktop` then turns on the AT-SPI2 bus and
starts the Firelamp shell.

## Desktops and window managers

`firelamp-desktops` (from the Settings work) installs GNOME, COSMIC, Xfce, Hyprland, niri
or Sway on demand; `firelamp-desktops serve` is the local API Settings > Desktops talks to.
Installed desktops appear as sessions on the SDDM login screen.

## Installer

Calamares (the CachyOS build) does an offline install: it copies the live system from the
ISO's squashfs, creates the user, removes the live-only bits (`firelamp-postinstall`),
rebuilds the initramfs and installs GRUB for BIOS or UEFI. Btrfs with `@`, `@home`,
`@cache` and `@log` subvolumes is the default; ext4 and XFS are offered. Its settings and
branding live in `profile/airootfs/usr/share/firelamp/calamares/`, and `firelamp-install`
(the "Install Firelamp OS" launcher) copies them over the package defaults before starting.

## Releases

Pushing a `v*` tag runs the same build and boot test, then publishes the ISO as a GitHub
Release with its SHA-256 (split into parts when it is over the 2 GiB asset limit).

## The shell contract

`/usr/local/bin/firelamp-shell` picks the first of:

1. `$FIRELAMP_SHELL_CMD`, any command (handy while developing)
2. `/usr/lib/firelamp/shell/firelamp-shell`, a compiled shell binary
3. `/usr/share/firelamp/shell/Main.qml`, run with Qt's `qml` tool

`build.sh` copies the repo's `shell/` folder to `/usr/share/firelamp/shell`, and
`shell/packages.x86_64` adds packages. To boot into plain Plasma, add `firelamp.noshell`
to the kernel line or `touch ~/.config/firelamp/no-shell`.

Qt apps run with `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1`, so they show up on the AT-SPI2 bus.
`firelamp-a11y-probe` prints the tree the AI sees.

## Build

On any Linux machine with Docker:

```sh
sudo iso/build.sh --docker
```

On Arch with `archiso` installed: `sudo iso/build.sh` (it adds the CachyOS key and repo
to the build host first, via `cachyos-setup.sh`). The ISO lands in `iso/out/`.

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
- **console only**: boots to a text login (`systemd.unit=multi-user.target`)
- **speech**: speakup screen reader
- add `firelamp.noshell` to the kernel line for plain Plasma without the Firelamp shell
