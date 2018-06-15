#!/bin/bash

set -e

# User variables
USER=azmo
GROUP=users
# comma separate
ADDITIONAL_GROUPS=wheel
UUID=1337
SHELL=zsh

# Custom Repository variables
GPGKEYID=0x6E225D252CEE6476
REPOURL=http://olympus.azmo.ninja:9912
REPONAME=azmo

if [ "$(id -u)" != 0 ]; then
    echo "Please execute with root rights."
    exit 1
fi

# Set up reflector
pacman -Syu && pacman -S --needed --noconfirm reflector
reflector --verbose --latest 8 --sort rate --protocol https \
    --save /etc/pacman.d/mirrorlist

# Essential stuff (terminal)
pacman -S --needed --noconfirm base-devel sudo ansible openssh gpm \
    netctl networkmanager zsh lsb-release git git-crypt pass pkgfile \
    neovim python-neovim python2-neovim wipe tmux

# Essential stuff (graphical)
grep vendor_id /proc/cpuinfo | grep -q Intel && IS_INTEL_CPU=1
lspci -k | grep -E "(VGA|3D)" | grep -i nvidia && HAS_NVIDIA_CARD=1
declare -a GRAPHIC_PACKAGES
[[ "${IS_INTEL_CPU}" ]] && \
    GRAPHIC_PACKAGES=("vulkan-intel" "libva-intel-driver" "libva" "libvdpau-va-gl")
[[ "${HAS_NVIDIA_CARD}" ]] && \
    GRAPHIC_PACKAGES=("nvidia" "nvidia-utils")
pacman -S --needed --noconfirm mesa xf86-input-libinput xorg xorg-xinit xterm \
    "${GRAPHIC_PACKAGES[@]}"

# Create and setup new user
if ! getent passwd ${USER} > /dev/null; then
    echo; echo "Adding ${USER}"
    useradd -u ${UUID} -m -g ${GROUP} -G ${ADDITIONAL_GROUPS} \
        -s /usr/bin/${SHELL} ${USER}
    passwd ${USER}
fi
if ! [ -f /etc/sudoers.d/${USER} ]; then
    cat > /etc/sudoers.d/${USER} <<- EOF
		${USER} ALL=(ALL) ALL
	EOF
fi

# Get custom Repository key and lsign it
pacman-key --recv-keys ${GPGKEYID}
pacman-key --lsign-key ${GPGKEYID}

# Enable custom Repository in pacman.conf
if ! grep -E -q "^[${REPONAME}]" /etc/pacman.conf; then
    cat >> /etc/pacman.conf <<- EOF
		[${REPONAME}]
		SigLevel = Required TrustedOnly
		Server = ${REPOURL}
EOF
fi

# install packages from custom repository
pacman -Sy --noconfirm
pacman -S --noconfirm --needed tomb tomb-kdf steghide

# install plasma
pacman -S --needed --noconfirm plasma-meta konsole dolphin
systemctl enable sddm.service

# Disable netctl and enable essential services
systemctl disable netctl && \
    systemctl enable gpm sshd NetworkManager NetworkManager-dispatcher

# fix pinentry symbolic link for kde/qt
# pinentry-gtk2 is default, we do not have that installed right now
rm /usr/bin/pinentry && ln -s /usr/bin/pinentry-qt /usr/bin/pinentry

# set keymap(s)
localectl --no-convert set-keymap de-latin1-nodeadkeys caps:escape
localectl --no-convert set-x11-keymap de pc105 nodeadkeys caps:escape
