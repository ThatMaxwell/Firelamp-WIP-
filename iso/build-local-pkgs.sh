#!/usr/bin/env bash
# Build the packages in iso/pkgbuilds/ into a local pacman repo that the ISO
# build uses ahead of [cachyos] and the Arch repos.
#
# Why: prebuilt packages can lag behind Arch's library bumps. cachyos-calamares-next
# 3.4.2-13 was linked against boost 1.91 while Arch shipped 1.92, so the
# installer failed to start ("libboost_python314.so.1.91.0: cannot open shared
# object file"). Building it here links it against the same libraries the ISO gets.
#
#   iso/build-local-pkgs.sh REPO_DIR    run as root on Arch (build.sh calls it)
set -euo pipefail

iso_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="${1:?usage: build-local-pkgs.sh REPO_DIR}"
name=firelamp-local

[[ $EUID -eq 0 ]] || { echo "build-local-pkgs.sh: run as root" >&2; exit 1; }
pacman -S --noconfirm --needed base-devel git >/dev/null

# makepkg refuses to run as root, so build as an unprivileged user that may
# install build dependencies with pacman.
id firelamp-build &>/dev/null || useradd -m firelamp-build
echo 'firelamp-build ALL=(root) NOPASSWD: /usr/bin/pacman' >/etc/sudoers.d/firelamp-build
chmod 440 /etc/sudoers.d/firelamp-build

mkdir -p "$repo"
build_root=/tmp/firelamp-pkgbuild
rm -rf "$build_root"
mkdir -p "$build_root/out"
chown firelamp-build: "$build_root/out"

for dir in "$iso_dir"/pkgbuilds/*/; do
    pkg="$(basename "$dir")"
    echo "build-local-pkgs: building $pkg"
    cp -a "$dir" "$build_root/$pkg"
    chown -R firelamp-build: "$build_root/$pkg"
    (cd "$build_root/$pkg" && sudo -u firelamp-build \
        env PKGDEST="$build_root/out" \
        makepkg --syncdeps --noconfirm --needed --nocheck --skippgpcheck)
done

cp "$build_root"/out/*.pkg.tar.* "$repo/"
repo-add -q "$repo/$name.db.tar.gz" "$repo"/*.pkg.tar.zst
ls -lh "$repo"
