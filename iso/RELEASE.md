Firelamp OS live and install ISO: KDE Plasma on Wayland, the CachyOS kernel, and the Firelamp shell on top.

### Download

If this release has `@ISO@.partNN` files, download all of them and join them:

```sh
cat @ISO@.part* > @ISO@          # Linux / macOS
copy /b @ISO@.part00+@ISO@.part01 @ISO@   # Windows (list every part)
sha256sum -c @ISO@.sha256
```

Otherwise download `@ISO@` directly.

### Try it

- **VirtualBox:** new VM, Linux / Arch Linux (64-bit), 4 GB RAM or more, Graphics Controller VMSVGA, ISO as the optical drive. Enable EFI to test UEFI boot.
- **USB stick:** write the ISO with Ventoy, Fedora Media Writer, balenaEtcher or `dd`.

The live session logs in by itself. To install, open **Install Firelamp OS** from the desktop or the app menu.

This build booted to the desktop in QEMU (BIOS and UEFI) with the compositor, the Firelamp shell and the AT-SPI2 tree checked, before it was published.
