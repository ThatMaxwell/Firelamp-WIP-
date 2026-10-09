#!/usr/bin/env bash
# Build the Firelamp OS live ISO (Arch + CachyOS repos and kernel).
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
        bash -c 'pacman -Syu --noconfirm --needed archiso git >/dev/null && /src/iso/cachyos-setup.sh && /src/iso/build.sh'
fi

if [[ $EUID -ne 0 ]]; then
    echo "build.sh: mkarchiso needs root. Run with sudo, or use --docker." >&2
    exit 1
fi
command -v mkarchiso >/dev/null || { echo "build.sh: install archiso first (pacman -S archiso)" >&2; exit 1; }
[[ -s /etc/pacman.d/cachyos-mirrorlist ]] || "$iso_dir/cachyos-setup.sh"

# Stage a copy of the profile so the shell can be layered in without touching
# the checked-in profile.
staged="$work_dir/profile"
rm -rf "$work_dir"
mkdir -p "$work_dir" "$out_dir"
cp -a "$iso_dir/profile" "$staged"

# Package sets (desktop, tools) live in iso/packages/, one file per set.
for set in "$iso_dir"/packages/*.x86_64; do
    printf '\n# From packages/%s\n' "$(basename "$set")" >>"$staged/packages.x86_64"
    cat "$set" >>"$staged/packages.x86_64"
done

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

# The assistant (agent/): /usr/lib/firelamp/agent, run as /usr/local/bin/firelamp-agent.
if [[ -d "$repo_dir/agent" ]]; then
    echo "build.sh: including the assistant from agent/"
    dest="$staged/airootfs/usr/lib/firelamp/agent"
    mkdir -p "$dest" "$staged/airootfs/usr/local/bin"
    cp -a "$repo_dir/agent/." "$dest/"
    rm -rf "$dest/test"
    find "$dest" -name __pycache__ -prune -exec rm -rf {} +
    chmod 755 "$dest/firelamp-agent"
    ln -sf /usr/lib/firelamp/agent/firelamp-agent "$staged/airootfs/usr/local/bin/firelamp-agent"
    if [[ -f "$repo_dir/agent/packages.x86_64" ]]; then
        printf '\n# From agent/packages.x86_64\n' >>"$staged/packages.x86_64"
        cat "$repo_dir/agent/packages.x86_64" >>"$staged/packages.x86_64"
    fi
fi

# Packages we rebuild ourselves (iso/pkgbuilds/) go in a local repo listed
# before [cachyos], so they win over the prebuilt ones.
if compgen -G "$iso_dir/pkgbuilds/*/PKGBUILD" >/dev/null; then
    local_repo="$work_dir/local-repo"
    "$iso_dir/build-local-pkgs.sh" "$local_repo"
    sed -i "0,/^\[cachyos\]/s||[firelamp-local]\nSigLevel = Optional TrustAll\nServer = file://$local_repo\n\n[cachyos]|" "$staged/pacman.conf"
    grep -q '^\[firelamp-local\]' "$staged/pacman.conf" || { echo "build.sh: could not add the local repo" >&2; exit 1; }
fi

export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$repo_dir" log -1 --format=%ct 2>/dev/null || date +%s)}"
mkarchiso -v -r -w "$work_dir/mkarchiso" -o "$out_dir" "$staged"

if [[ -n "${HOST_UID:-}" ]]; then
    chown -R "$HOST_UID:${HOST_GID:-$HOST_UID}" "$out_dir"
fi
ls -lh "$out_dir"/*.iso
