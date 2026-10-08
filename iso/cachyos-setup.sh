#!/usr/bin/env bash
# Prepare an Arch build host to install packages from the CachyOS repository:
# trust the CachyOS signing key, write a mirrorlist, and install the official
# keyring and mirrorlist packages. build.sh runs this before mkarchiso.
set -euo pipefail

key=F3B607488DB35A47   # CachyOS package signing key
mirrorlist=/etc/pacman.d/cachyos-mirrorlist

pacman-key --init >/dev/null 2>&1 || true
if ! pacman-key --list-keys "$key" >/dev/null 2>&1; then
    pacman-key --recv-keys "$key" --keyserver hkps://keyserver.ubuntu.com ||
        pacman-key --recv-keys "$key" --keyserver hkps://keys.openpgp.org
    pacman-key --lsign-key "$key"
fi

# Bootstrap mirrorlist; replaced by the cachyos-mirrorlist package below.
if [[ ! -s "$mirrorlist" ]]; then
    cat >"$mirrorlist" <<'LIST'
Server = https://cdn77.cachyos.org/repo/$arch/$repo
Server = https://mirror.cachyos.org/repo/$arch/$repo
LIST
fi

if ! grep -q '^\[cachyos\]' /etc/pacman.conf; then
    sed -i '0,/^\[core\]/s//[cachyos]\nInclude = \/etc\/pacman.d\/cachyos-mirrorlist\n\n[core]/' /etc/pacman.conf
fi

pacman -Sy --noconfirm --needed cachyos-keyring cachyos-mirrorlist
pacman-key --populate cachyos
