#!/usr/bin/env python3
"""Boot a Firelamp OS ISO in QEMU, wait for the desktop, and capture it.

    iso/test-boot.py iso/out/firelamp-*.iso --out boot-test

Writes to the output folder:
    serial.log      everything the VM printed on its serial port
    desktop.png     screenshot once the desktop reported in
    frames/*.png    a screenshot every few seconds while booting
    boot.gif        those frames as an animation (if ffmpeg is installed)

Exits non-zero if the desktop session or the AT-SPI2 tree never came up.
"""
import argparse
import os
import re
import shutil
import socket
import subprocess
import sys
import time


def hmp(sock_path, command):
    """Send one human-monitor command to QEMU."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(10)
        s.connect(sock_path)
        time.sleep(0.2)
        s.recv(65536)  # banner
        s.sendall((command + "\n").encode())
        time.sleep(0.8)
        try:
            return s.recv(65536).decode(errors="replace")
        except socket.timeout:
            return ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("iso")
    ap.add_argument("--out", default="boot-test")
    ap.add_argument("--timeout", type=int, default=600, help="seconds to wait for the desktop")
    ap.add_argument("--memory", default="4096")
    ap.add_argument("--uefi", action="store_true", help="boot with OVMF instead of BIOS")
    ap.add_argument("--frame-interval", type=float, default=4.0)
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    frames = os.path.join(out, "frames")
    os.makedirs(frames, exist_ok=True)
    serial = os.path.join(out, "serial.log")
    mon = os.path.join(out, "monitor.sock")
    for p in (serial, mon):
        if os.path.exists(p):
            os.remove(p)

    kvm = os.access("/dev/kvm", os.R_OK | os.W_OK)
    cmd = [
        "qemu-system-x86_64",
        "-m", args.memory,
        "-smp", str(min(os.cpu_count() or 2, 4)),
        "-cdrom", os.path.abspath(args.iso),
        "-boot", "d",
        "-vga", "virtio",
        "-display", "none",
        "-serial", f"file:{serial}",
        "-monitor", f"unix:{mon},server,nowait",
        "-device", "virtio-tablet-pci",
        "-nic", "user,model=virtio-net-pci",
        "-no-reboot",
        # Tells the live session to skip the shell's first-boot naming screen.
        "-fw_cfg", "name=opt/firelamp/skip-onboarding,string=1",
    ]
    cmd += ["-enable-kvm", "-cpu", "host"] if kvm else ["-accel", "tcg", "-cpu", "max"]
    if args.uefi:
        for fw in ("/usr/share/ovmf/OVMF.fd", "/usr/share/OVMF/OVMF_CODE.fd", "/usr/share/edk2/x64/OVMF.4m.fd"):
            if os.path.exists(fw):
                cmd += ["-bios", fw]
                break
        else:
            sys.exit("test-boot: --uefi needs OVMF installed")

    print("test-boot:", "KVM" if kvm else "TCG (slow, no KVM)", flush=True)
    print("test-boot:", " ".join(cmd), flush=True)
    vm = subprocess.Popen(cmd)

    deadline = time.time() + args.timeout
    frame = 0
    report = ""
    try:
        while time.time() < deadline:
            if vm.poll() is not None:
                print(f"test-boot: QEMU exited early with {vm.returncode}", flush=True)
                break
            time.sleep(args.frame_interval)
            if os.path.exists(mon):
                path = os.path.join(frames, f"{frame:04d}.png")
                hmp(mon, f"screendump {path} -f png")
                frame += 1
            if os.path.exists(serial):
                with open(serial, errors="replace") as fh:
                    text = fh.read()
                if "=== END FIRELAMP BOOT REPORT ===" in text:
                    report = text[text.index("=== FIRELAMP BOOT REPORT ==="):]
                    break
        # Let the desktop animations settle, then take the hero shot.
        if vm.poll() is None and os.path.exists(mon):
            time.sleep(3)
            hmp(mon, f"screendump {os.path.join(out, 'desktop.png')} -f png")
            shutil.copy(os.path.join(out, "desktop.png"), os.path.join(frames, f"{frame:04d}.png"))
            # Tap Super: it should open the Firelamp launcher, not Plasma's.
            hmp(mon, "sendkey meta_l")
            time.sleep(3)
            hmp(mon, f"screendump {os.path.join(out, 'super.png')} -f png")
            # The guest writes the shell's trace of that keypress to the serial port.
            for _ in range(10):
                with open(serial, errors="replace") as fh:
                    text = fh.read()
                if "=== END FIRELAMP SUPER DEBUG ===" in text:
                    print(text[text.index("=== FIRELAMP SUPER DEBUG ==="):text.index("=== END FIRELAMP SUPER DEBUG ===")], flush=True)
                    break
                time.sleep(1)
            else:
                print("test-boot: no Super debug on the serial port", flush=True)
    finally:
        if vm.poll() is None:
            try:
                hmp(mon, "quit")
            except OSError:
                pass
            try:
                vm.wait(15)
            except subprocess.TimeoutExpired:
                vm.kill()

    if shutil.which("ffmpeg") and frame > 1:
        subprocess.run([
            "ffmpeg", "-loglevel", "error", "-y", "-framerate", "3",
            "-i", os.path.join(frames, "%04d.png"),
            "-vf", "scale=800:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse",
            os.path.join(out, "boot.gif"),
        ], check=False)

    print(report or "test-boot: no boot report on the serial port", flush=True)
    m = re.search(r"FIRELAMP_ATSPI_OK apps=(\d+)", report)
    ok = bool(m) and int(m.group(1)) > 0 and "compositor: NOT RUNNING" not in report \
        and "shell: NOT RUNNING" not in report and re.search(r"^kernel: .*cachyos", report, re.M) is not None \
        and "installer: NOT INSTALLED" not in report and "login theme: ERROR" not in report \
        and "installer window: RUNNING" in report and "terminal window: RUNNING" in report \
        and "files window: RUNNING" in report and "web window: RUNNING" in report
    print("test-boot:", "PASS" if ok else "FAIL", flush=True)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
