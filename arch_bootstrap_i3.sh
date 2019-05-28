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
common_user
common_essential
common_add_yay_user
common_install_yay
common_graphical

# install i3 and needed packages
pacman -S --needed --noconfirm i3-gaps \
    polkit-gnome pulseaudio xss-lock scrot wmctrl
common_install_aur polybar i3lock-fancy-git i3lock-color-git

common_remove_yay_user
common_services
common_networkmanager_iwd
common_keymap
