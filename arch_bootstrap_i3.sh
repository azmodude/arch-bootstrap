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
pacman -Sy && pacman -S --needed --noconfirm reflector
reflector --verbose --latest 8 --sort rate --protocol https \
    --save /etc/pacman.d/mirrorlist

# Essential stuff (terminal)
pacman -S --needed --noconfirm base-devel sudo ansible openssh gpm \
    netctl networkmanager zsh keychain lsb-release git git-crypt gopass pass \
    pkgfile neovim python-neovim python2-neovim wipe tmux expect

# Essential stuff (graphical)
grep vendor_id /proc/cpuinfo | grep -q Intel && IS_INTEL_CPU=1
lspci -k | grep -E "(VGA|3D)" | grep -i nvidia && HAS_NVIDIA_CARD=1
declare -a GRAPHIC_PACKAGES
libvdpau-va-gl
[[ "${IS_INTEL_CPU}" ]] && \
    GRAPHIC_PACKAGES=("vulkan-intel" "libva-intel-driver" "libva" "libvdpau-va-gl")
[[ "${HAS_NVIDIA_CARD}" ]] && \
    GRAPHIC_PACKAGES=("nvidia" "nvidia-utils" "libva-vdpau-driver")
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
pacman-key --keyserver hkp://eu.pool.sks-keyservers.net --recv-keys ${GPGKEYID}
pacman-key --lsign-key ${GPGKEYID}

# Enable custom Repository in pacman.conf
if ! grep -E -q "^\\[${REPONAME}\\]" /etc/pacman.conf; then
    cat >> /etc/pacman.conf <<- EOF
		[${REPONAME}]
		SigLevel = Required TrustedOnly
		Server = ${REPOURL}
EOF
fi

# install packages from custom repository
pacman -Sy --noconfirm
pacman -S --noconfirm --needed tomb tomb-kdf steghide advanced-ssh-config \
    myrepos

# install i3 and needed packages
pacman -S --needed --noconfirm lightdm lightdm-webkit2-greeter i3-gaps \
    polkit-gnome gnome-terminal

# Setup lightdm
if [[ ! -d /etc/lightdm/lightdm.conf.d ]]; then
    mkdir /etc/lightdm/lightdm.conf.d
fi
if [[ ! -f /etc/lightdm/lightdm.conf.d/webkit2.conf ]]; then
        cat > /etc/lightdm/lightdm.conf.d/webkit2.conf << EOF
[Seat:*]
greeter-session=lightdm-webkit2-greeter
EOF
fi
# Enable lightdm
systemctl enable lightdm

# get some nerd-fonts
# use fork until nerd fonts are fixed
NERDBASE="https://github.com/haasosaurus/nerd-fonts/blob/regen-mono-font-fix/patched-fonts"
su -l $USER -c "mkdir -p ~/.local/share/fonts"
# Hack
if [[ ! -d /home/$USER/.local/share/fonts/nerd-fonts-hack ]]; then
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Regular Nerd Font Complete.ttf' $NERDBASE/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Regular Nerd Font Complete Mono.ttf' $NERDBASE/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete%20Mono.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Bold Nerd Font Complete.ttf' $NERDBASE/Hack/Bold/complete/Hack%20Bold%20Nerd%20Font%20Complete.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Bold Nerd Font Complete Mono.ttf' $NERDBASE/Hack/Bold/complete/Hack%20Bold%20Nerd%20Font%20Complete%20Mono.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Bold Italic Nerd Font Complete.ttf' $NERDBASE/Hack/BoldItalic/complete/Hack%20Bold%20Italic%20Nerd%20Font%20Complete.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Bold Italic Nerd Font Complete Mono.ttf' $NERDBASE/Hack/BoldItalic/complete/Hack%20Bold%20Italic%20Nerd%20Font%20Complete%20Mono.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Italic Nerd Font Complete.ttf' $NERDBASE/Hack/Italic/complete/Hack%20Italic%20Nerd%20Font%20Complete.ttf?raw=true)"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-hack && cd nerd-fonts-hack && curl -fLo 'Hack Italic Nerd Font Complete Mono.ttf' $NERDBASE/Hack/Italic/complete/Hack%20Italic%20Nerd%20Font%20Complete%20Mono.ttf?raw=true)"
fi
# Ubuntu Mono
if [[ ! -d /home/$USER/.local/share/fonts/nerd-fonts-ubuntu-mono ]]; then
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Nerd Font Complete.ttf' '$NERDBASE/UbuntuMono/Regular/complete/Ubuntu%20Mono%20Nerd%20Font%20Complete.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Nerd Font Complete Mono.ttf' '$NERDBASE/UbuntuMono/Regular/complete/Ubuntu%20Mono%20Nerd%20Font%20Complete%20Mono.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Italic Nerd Font Complete.ttf' '$NERDBASE/UbuntuMono/Regular-Italic/complete/Ubuntu%20Mono%20Italic%20Nerd%20Font%20Complete.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Italic Nerd Font Complete Mono.ttf' '$NERDBASE/UbuntuMono/Regular-Italic/complete/Ubuntu%20Mono%20Italic%20Nerd%20Font%20Complete%20Mono.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Bold Nerd Font Complete.ttf' '$NERDBASE/UbuntuMono/Bold/complete/Ubuntu%20Mono%20Bold%20Nerd%20Font%20Complete.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Bold Nerd Font Complete Mono.ttf' '$NERDBASE/UbuntuMono/Bold/complete/Ubuntu%20Mono%20Bold%20Nerd%20Font%20Complete%20Mono.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Bold Italic Nerd Font Complete.ttf' '$NERDBASE/UbuntuMono/Bold-Italic/complete/Ubuntu%20Mono%20Bold%20Italic%20Nerd%20Font%20Complete.ttf?raw=true')"
    su -l $USER -c "(cd ~/.local/share/fonts && mkdir -p nerd-fonts-ubuntu-mono && cd nerd-fonts-ubuntu-mono && curl -fLo 'Ubuntu Mono Bold Italic Nerd Font Complete Mono.ttf' '$NERDBASE/UbuntuMono/Bold-Italic/complete/Ubuntu%20Mono%20Bold%20Italic%20Nerd%20Font%20Complete%20Mono.ttf?raw=true')"
fi
su -l $USER -c "fc-cache -fv ~/.local/share/fonts"

# Disable netctl and enable essential services
systemctl disable netctl && \
    systemctl enable gpm sshd NetworkManager NetworkManager-dispatcher

# set keymap(s)
localectl --no-convert set-keymap de-latin1-nodeadkeys caps:escape
localectl --no-convert set-x11-keymap de pc105 nodeadkeys caps:escape
