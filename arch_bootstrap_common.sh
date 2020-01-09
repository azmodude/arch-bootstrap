#!/bin/bash

# User variables
user=azmo
uuid=1337
user_fullname="Gordon Schulz"
primarygroup=azmo
primarygid=1000
# comma separate groups
additional_groups=wheel,users
usersgid=100
shell=zsh

packager="Gordon Schulz <gordon.schulz@gmail.com>"

# Custom Repository variables
gpgkeyid=2500B0062F13CADEEB199BE2A1A520A41200F7A8
repourl=http://olympus.azmo.ninja:9912
reponame=azmo

common_set_time() {
    timedatectl set-ntp true
    hwclock --systohc
}

common_reflector() {
    # Set up reflector
    # Do a full upgrade first so we don't run into partial-upgrade issues
    pacman -Suy --noconfirm && pacman -S --needed --noconfirm reflector
    reflector --verbose --latest 15 --sort rate --protocol https \
        --country DE --country NL --save /etc/pacman.d/mirrorlist
}

common_custom_repo() {
    # Get custom Repository key and lsign it
    pacman-key --keyserver hkp://eu.pool.sks-keyservers.net \
        --recv-keys ${gpgkeyid}
    pacman-key --lsign-key ${gpgkeyid}
    # Enable custom Repository in pacman.conf
    if ! grep -E -q "^\\[${reponame}\\]" /etc/pacman.conf; then
        cat >> /etc/pacman.conf <<- EOF
			[${reponame}]
			SigLevel = Required TrustedOnly
			Server = ${repourl}
		EOF
	fi
}

common_essential() {
# Essential stuff (terminal)
    pacman -S --needed --noconfirm base-devel sudo ansible openssh gpm \
        netctl networkmanager iwd zsh keychain lsb-release git git-crypt \
        gopass pass oath-toolkit xclip xsel pkgfile neovim python-neovim \
        wipe tmux expect
}

common_graphical() {
    # Essential stuff (graphical)
    grep vendor_id /proc/cpuinfo | grep -q Intel && is_intel_cpu=1
    lspci -k | grep -E "(VGA|3D)" | grep -i nvidia && has_nvidia_card=1
    declare -a graphic_packages
    [[ "${is_intel_cpu}" ]] && \
        graphic_packages=("xf86-video-intel" "vulkan-intel" "libva-intel-driver" "libva" "libvdpau-va-gl")
    [[ "${has_nvidia_card}" ]] && \
        graphic_packages=("nvidia" "nvidia-utils" "libva-vdpau-driver")
    pacman -S --needed --noconfirm mesa xf86-input-libinput xorg xorg-xinit \
        xterm "${graphic_packages[@]}"
}

common_user() {
    # Create and setup new user
    if ! getent passwd ${user} >/dev/null; then
        echo
        echo "Adding ${user}"
        groupadd -g "${primarygid}" "${primarygroup}"
        groupadd -g "${usersgid}" users || groupmod -g "${usersgid}" users

        useradd -u "${uuid}" -m -g "${primarygroup}" -G "${additional_groups}" \
            -s "/usr/bin/${shell}" "${user}"
        chfn --full-name "${user_fullname}" "${user}"
        passwd "${user}"
    fi
    if ! [ -f /etc/sudoers.d/${user} ]; then
		cat > /etc/sudoers.d/${user} <<- EOF
			${user} ALL=(ALL) ALL
		EOF
    fi
}

common_add_yay_user() {
    useradd -m -p yay yay
    echo "yay ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/yay
    mkdir /home/yay/.gnupg && \
        echo "keyserver-options auto-key-retrieve" > \
        /home/yay/.gnupg/gpg.conf && \
    chown -R yay /home/yay/.gnupg
}
common_install_yay() {
    tmpdir=$(mktemp -d) && chown -R yay "${tmpdir}"
    su -l -c "git clone https://aur.archlinux.org/yay-bin.git ${tmpdir}" yay
    su -l -c "cd ${tmpdir} && makepkg -srci --noconfirm --needed" yay
}
common_remove_yay_user() {
    userdel -rf yay
    rm -f /etc/sudoers.d/yay
}

common_install_aur() {
    sudo -u yay -i -H yay -Sy --cleanafter --removemake --pgpfetch \
        --noconfirm --needed "${@}"
}

common_services() {
    # Disable netctl and enable essential services
    systemctl disable netctl && \
        systemctl enable gpm sshd NetworkManager NetworkManager-dispatcher iwd
}

common_keymap() {
    # set keymap(s)
    localectl --no-convert set-keymap de-latin1-nodeadkeys
    localectl --no-convert set-x11-keymap de pc105 nodeadkeys caps:escape
}

common_lightdm() {
    # Setup lightdm
    if [[ ! -d /etc/lightdm/lightdm.conf.d ]]; then
        mkdir /etc/lightdm/lightdm.conf.d
    fi
    if [[ ! -f /etc/lightdm/lightdm.conf.d/webkit2.conf ]]; then
		cat > /etc/lightdm/lightdm.conf.d/webkit2.conf <<- EOF
		[Seat:*]
		greeter-session=lightdm-webkit2-greeter
		EOF
	fi
    # Enable lightdm
    systemctl enable lightdm
}

common_networkmanager_iwd() {
    cat > /etc/NetworkManager/conf.d/wifi_backend.conf <<- EOF
[device]
wifi.backend=iwd
	EOF
}

common_makepkg_conf() {
    sed -i -r "s/^#MAKEFLAG.*/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf
    sed -i -r "s/^#PACKAGER.*/PACKAGER=\"${packager}\"/" /etc/makepkg.conf
}
