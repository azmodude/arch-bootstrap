#!/bin/bash

set -e

if [ "$(id -u)" != 0 ]; then
    echo "Please execute with root rights."
    exit 1
fi
curdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${curdir}/arch_bootstrap_common.sh"

common_set_time
common_reflector
common_essential
common_user
common_makepkg_conf
common_add_yay_user
common_install_yay
common_graphical

# install i3 and needed packages
pacman -S --needed --noconfirm i3-gaps i3status \
    arandr pavucontrol pulseaudio xss-lock \
    maim wmctrl gtk4 gtk3 gtk2 udiskie dunst rofi picom gnome-themes-extra \
    adwaita-icon-theme polkit-gnome brightnessctl feh kitty lightdm \
    lightdm-webkit2-greeter light-locker

# aur
common_install_aur tomb i3lock-fancy-git

common_remove_yay_user
common_services
common_networkmanager_iwd
common_keymap
common_lightdm
