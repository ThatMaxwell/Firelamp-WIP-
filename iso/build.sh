#!/usr/bin/env bash
# Build the Firelamp OS live ISO.
#
#   iso/build.sh            build on an Arch Linux host (run as root, needs archiso)
#   iso/build.sh --docker   build inside an archlinux Docker container (any Linux host)
#
# The ISO lands in iso/out/. If the repo has a shell/ folder (the QML desktop
# shell), it is baked into the image at /usr/share/firelamp/shell, and
# shell/packages.x86_64 (if present) adds extra packages.
set -euo pipefail

iso_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname "$iso_dir")"
work_dir="${FIRELAMP_WORK_DIR:-$iso_dir/work}"
out_dir="${FIRELAMP_OUT_DIR:-$iso_dir/out}"

if [[ "${1:-}" == "--docker" ]]; then
    image="${FIRELAMP_BUILD_IMAGE:-archlinux:latest}"
    exec docker run --rm --privileged \
        -v "$repo_dir:/src" \
        -e FIRELAMP_WORK_DIR=/tmp/firelamp-work \
        -e FIRELAMP_OUT_DIR=/src/iso/out \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
        "$image" \
        bash -c 'pacman -Syu --noconfirm --needed archiso git >/dev/null && /src/iso/build.sh'
fi

if [[ $EUID -ne 0 ]]; then
    echo "build.sh: mkarchiso needs root. Run with sudo, or use --docker." >&2
    exit 1
fi
command -v mkarchiso >/dev/null || { echo "build.sh: install archiso first (pacman -S archiso)" >&2; exit 1; }

# Stage a copy of the profile so the shell can be layered in without touching
# the checked-in profile.
staged="$work_dir/profile"
rm -rf "$work_dir"
mkdir -p "$work_dir" "$out_dir"
cp -a "$iso_dir/profile" "$staged"

if [[ -d "$repo_dir/shell" ]]; then
    echo "build.sh: including desktop shell from shell/"
    dest="$staged/airootfs/usr/share/firelamp/shell"
    mkdir -p "$dest"
    cp -a "$repo_dir/shell/." "$dest/"
    if [[ -f "$repo_dir/shell/packages.x86_64" ]]; then
        printf '\n# From shell/packages.x86_64\n' >>"$staged/packages.x86_64"
        cat "$repo_dir/shell/packages.x86_64" >>"$staged/packages.x86_64"
    fi
fi

export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$repo_dir" log -1 --format=%ct 2>/dev/null || date +%s)}"
mkarchiso -v -r -w "$work_dir/mkarchiso" -o "$out_dir" "$staged"

if [[ -n "${HOST_UID:-}" ]]; then
    chown -R "$HOST_UID:${HOST_GID:-$HOST_UID}" "$out_dir"
fi
ls -lh "$out_dir"/*.iso
