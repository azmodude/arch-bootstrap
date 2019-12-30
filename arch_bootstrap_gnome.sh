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

# install gnome
pacman -S --needed --noconfirm gnome gnome-extra gtk2
systemctl enable gdm.service
# fix pinentry symbolic link
# pinentry-gnome is retarded, therefore use pinentry-gtk2
rm /usr/bin/pinentry && ln -s /usr/bin/pinentry-gtk-2 /usr/bin/pinentry

common_remove_yay_user
common_services
common_networkmanager_iwd
common_keymap
