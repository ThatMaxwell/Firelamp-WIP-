#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="firelamp"
iso_label="FIRELAMP_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Firelamp OS <https://github.com/ThatMaxwell/Firelamp-WIP->"
iso_application="Firelamp OS Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="firelamp"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/10-firelamp-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/firelamp-session"]="0:0:755"
  ["/usr/local/bin/firelamp-shell"]="0:0:755"
  ["/usr/local/bin/firelamp-a11y-probe"]="0:0:755"
  ["/usr/local/bin/firelamp-boot-report"]="0:0:755"
)
kernel_params_x86_64="quiet loglevel=3 rd.udev.log_level=3"
