#!/bin/bash

set -e

if [ "$(id -u)" != 0 ]; then
    echo "Please execute with root rights."
    exit 1
fi
curdir="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"
source "${curdir}/arch_bootstrap_common.sh"

common_set_time
common_reflector
common_essential
if lsmod | grep -q zfs; then
    common_user_zfs
else
    common_user
fi
common_user_subuidgid
common_makepkg_conf
common_add_paru_user
common_install_paru
common_graphical

# install plasma
pacman -S --needed --noconfirm plasma-meta konsole dolphin \
    kdegraphics-thumbnailers ffmpegthumbs gtk2
# aur
common_install_aur tomb

common_remove_paru_user
common_services
common_networkmanager_iwd
common_keymap

systemctl enable sddm.service NetworkManager NetworkManager-dispatcher
