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
if lsmod | grep -q zfs; then
    common_user_zfs
else
    common_user
fi
common_user_subuidgid
common_makepkg_conf
common_add_chaotic_aur
common_add_paru_user
common_install_paru
common_graphical

# install i3 and needed packages
pacman -S --needed --noconfirm i3-gaps i3status \
    arandr pavucontrol xss-lock \
    maim wmctrl gtk4 gtk3 gtk2 udiskie dunst rofi picom gnome-themes-extra \
    adwaita-icon-theme polkit-gnome brightnessctl feh kitty lightdm \
    lightdm-webkit2-greeter pipewire-pulse pipewire gst-plugin-pipewire \
    pipewire-zeroconf

# aur
common_install_aur tomb i3lock-fancy-git

common_remove_paru_user
common_services
common_networkmanager_iwd
common_keymap
common_lightdm

systemctl enable NetworkManager NetworkManager-dispatcher
