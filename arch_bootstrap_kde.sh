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
common_user
common_makepkg_conf
common_add_yay_user
common_install_yay
common_graphical

# install plasma
pacman -S --needed --noconfirm plasma-meta konsole dolphin \
    kdegraphics-thumbnailers ffmpegthumbs gtk2
systemctl enable sddm.service
# fix pinentry symbolic link
rm /usr/bin/pinentry && ln -s /usr/bin/pinentry-qt /usr/bin/pinentry

common_remove_yay_user
common_services
common_networkmanager_iwd
common_keymap
