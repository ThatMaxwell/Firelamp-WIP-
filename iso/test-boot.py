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
import json
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


def qmp_click(sock_path, x, y, width, height):
    """Click at (x, y) on the guest screen. QEMU's tablet is absolute, and HMP's mouse_move only
    sends relative motion, so use QMP's input-send-event with the tablet's 0..32767 axes."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(10)
        s.connect(sock_path)
        f = s.makefile("rw")
        f.readline()  # greeting

        def cmd(c):
            f.write(json.dumps(c) + "\n")
            f.flush()
            while True:
                r = json.loads(f.readline())
                if "return" in r or "error" in r:
                    return r
        cmd({"execute": "qmp_capabilities"})
        ax = lambda axis, v, size: {"type": "abs", "data": {"axis": axis, "value": round(v * 32767 / max(size - 1, 1))}}
        btn = lambda down: {"type": "btn", "data": {"button": "left", "down": down}}
        r = cmd({"execute": "input-send-event", "arguments": {"events": [ax("x", x, width), ax("y", y, height)]}})
        time.sleep(0.4)
        cmd({"execute": "input-send-event", "arguments": {"events": [btn(True)]}})
        time.sleep(0.15)
        cmd({"execute": "input-send-event", "arguments": {"events": [btn(False)]}})
        return r


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    return int.from_bytes(head[16:20], "big"), int.from_bytes(head[20:24], "big")


def capsule_stop(mon, qmp, serial, out):
    """The guest starts a real task, finds the capsule's Stop over AT-SPI and prints its screen
    position; click it like a person would (QEMU's tablet) and print what the agent says."""
    def serial_text():
        with open(serial, errors="replace") as fh:
            return fh.read()
    # The guest sends a position per try (it re-measures if a click missed), then one RESULT.
    clicked, deadline = 0, time.time() + 240
    while time.time() < deadline:
        text = serial_text()
        m = re.search(r"=== FIRELAMP STOP (RESULT|SKIPPED)[^\n]*", text)
        if m:
            print("test-boot:", m.group(0), flush=True)
            return
        tries = list(re.finditer(r"=== FIRELAMP STOP AT (\d+) (\d+)[^\n]*", text))
        if len(tries) > clicked:
            x, y = int(tries[-1].group(1)), int(tries[-1].group(2))
            clicked = len(tries)
            print("test-boot:", tries[-1].group(0), flush=True)
            if clicked == 1:
                hmp(mon, f"screendump {os.path.join(out, 'capsule.png')} -f png")
            try:
                width, height = png_size(os.path.join(out, "capsule.png"))
            except OSError:
                width, height = 1280, 800
            r = qmp_click(qmp, x, y, width, height)
            if "error" in r:
                print("test-boot: QMP click failed:", r["error"], flush=True)
            time.sleep(1)
            hmp(mon, f"screendump {os.path.join(out, f'capsule-click{clicked}.png')} -f png")
            deadline = time.time() + 120
        time.sleep(1)
    print("test-boot: capsule Stop test: no result from the guest", flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("iso")
    ap.add_argument("--out", default="boot-test")
    ap.add_argument("--timeout", type=int, default=600, help="seconds to wait for the desktop")
    ap.add_argument("--memory", default="4096")
    ap.add_argument("--uefi", action="store_true", help="boot with OVMF instead of BIOS")
    ap.add_argument("--frame-interval", type=float, default=4.0)
    ap.add_argument("--test-brain", default=os.environ.get("FIRELAMP_TEST_BRAIN", ""),
                    help="BASE|MODEL of an OpenAI-compatible server the guest can reach; runs the capsule Stop test")
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    frames = os.path.join(out, "frames")
    os.makedirs(frames, exist_ok=True)
    serial = os.path.join(out, "serial.log")
    mon = os.path.join(out, "monitor.sock")
    qmp = os.path.join(out, "qmp.sock")
    for p in (serial, mon, qmp):
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
        "-qmp", f"unix:{qmp},server,nowait",
        "-device", "virtio-tablet-pci",
        "-nic", "user,model=virtio-net-pci",
        "-no-reboot",
        # Tells the live session to skip the shell's first-boot naming screen.
        "-fw_cfg", "name=opt/firelamp/skip-onboarding,string=1",
    ]
    if args.test_brain:
        cmd += ["-fw_cfg", f"name=opt/firelamp/test-brain,string={args.test_brain}"]
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
            # Tap Super (held 150 ms, so KWin counts a modifier-only tap): it should open the Firelamp launcher.
            hmp(mon, "sendkey meta_l 150")
            time.sleep(3)
            hmp(mon, f"screendump {os.path.join(out, 'super.png')} -f png")
            # Meta+Space goes through kglobalaccel instead of KWin's modifier-only tap.
            time.sleep(2)
            hmp(mon, "sendkey meta_l-spc 150")
            time.sleep(3)
            hmp(mon, f"screendump {os.path.join(out, 'metaspace.png')} -f png")
            hmp(mon, "sendkey meta_l-spc 150")  # close the launcher again
            # The guest writes the shell's trace of that keypress to the serial port.
            for _ in range(10):
                with open(serial, errors="replace") as fh:
                    text = fh.read()
                if "=== END FIRELAMP SUPER DEBUG ===" in text:
                    for m in re.finditer(r"=== FIRELAMP SUPER DEBUG ===(.*?)=== END FIRELAMP SUPER DEBUG ===", text, re.S):
                        print("test-boot: shell trace after a key:", m.group(1).strip(), flush=True)
                    break
                time.sleep(1)
            else:
                print("test-boot: no Super debug on the serial port", flush=True)
            if args.test_brain:
                capsule_stop(mon, qmp, serial, out)
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
        and "files window: RUNNING" in report and "web window: RUNNING" in report \
        and "agent: RUNNING" in report
    print("test-boot:", "PASS" if ok else "FAIL", flush=True)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
