#!/bin/bash

# User variables
user=azmo
user_fullname="Gordon Schulz"
uuid=1000
primarygroup=azmo
primarygid=1000
# comma separate groups
additional_groups=wheel,users
usersgid=100
shell=zsh

packager="Gordon Schulz <gordon@gordonschulz.de>"

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

common_essential() {
    # Essential stuff (terminal)
    pacman -S --needed --noconfirm base-devel sudo ansible openssh gpm \
        pass iwd systemd-resolvconf zsh lsb-release git git-crypt \
        xclip xsel neovim python-neovim wipe tmux networkmanager \
	chezmoi
}

common_graphical() {
    # Essential stuff (graphical)
    grep vendor_id /proc/cpuinfo | grep -q Intel && is_intel_cpu=1
    lspci -k | grep -E "(VGA|3D)" | grep -i nvidia && has_nvidia_card=1
    declare -a graphic_packages
    [[ "${is_intel_cpu}" ]] &&
        graphic_packages=("xf86-video-intel" "vulkan-intel" "libva-intel-driver" "libva" "libvdpau-va-gl")
    [[ "${has_nvidia_card}" ]] &&
        graphic_packages=("nvidia" "nvidia-utils" "libva-vdpau-driver")
    pacman -S --needed --noconfirm mesa xf86-input-libinput xorg xorg-xinit \
        xterm "${graphic_packages[@]}"
}

common_user_zfs() {
    # create new dataset for user
    if ! zfs list "dpool/home/${user}" 2>/dev/null; then
        zfs create "dpool/home/${user}"
    fi
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
        # as the home directory already exists as zfs dataset
        # copy files from skel over manually and adjust permissions
        cp -r /etc/skel/. "/home/${user}"
        chown -R "${user}:${primarygroup}" "/home/${user}" &&
            chmod 700 "/home/${user}"
    fi
    if ! [ -f "/etc/sudoers.d/${user}" ]; then
        cat >"/etc/sudoers.d/${user}" <<-EOF
			${user} ALL=(ALL) ALL
		EOF
    fi
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
    if ! [ -f "/etc/sudoers.d/${user}" ]; then
        cat >"/etc/sudoers.d/${user}" <<-EOF
			${user} ALL=(ALL) ALL
		EOF
    fi
}

common_add_paru_user() {
    useradd -m -p paru paru
    echo "paru ALL=(ALL) NOPASSWD: /usr/bin/pacman" >/etc/sudoers.d/paru
    mkdir /home/paru/.gnupg &&
        echo "keyserver-options auto-key-retrieve" > \
            /home/paru/.gnupg/gpg.conf &&
        echo "keyserver hkps://keyserver.ubuntu.com" >> \
            /home/paru/.gnupg/gpg.conf &&
        chown -R "paru:users" /home/paru/.gnupg &&
        chmod 700 /home/paru/.gnupg
}
common_install_paru() {
    tmpdir=$(mktemp -d) && chown -R paru "${tmpdir}"
    su -l -c "git clone https://aur.archlinux.org/paru-bin.git ${tmpdir}" paru
    su -l -c "cd ${tmpdir} && makepkg -srci --noconfirm --needed" paru
}
common_remove_paru_user() {
    userdel -rf paru
    rm -f /etc/sudoers.d/paru
}

common_install_aur() {
    sudo -u paru -i -H paru -Sy --cleanafter --removemake --pgpfetch \
        --noconfirm --needed "${@}"
}

common_services() {
    # enable mandatory services
    systemctl enable --now gpm sshd systemd-resolved systemd-networkd iwd
    # create link to systemd-resolved stub
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
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
        cat >/etc/lightdm/lightdm.conf.d/webkit2.conf <<-EOF
		[Seat:*]
		greeter-session=lightdm-webkit2-greeter
		EOF
    fi
    # Enable lightdm
    systemctl enable lightdm
}

common_networkmanager_iwd() {
    cat >/etc/NetworkManager/conf.d/wifi_backend.conf <<-EOF
[device]
wifi.backend=iwd
	EOF
}

common_makepkg_conf() {
    # number of processors
    sed -i -r "s/^#MAKEFLAG.*/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf
    # packager
    sed -i -r "s/^#PACKAGER.*/PACKAGER=\"${packager}\"/" /etc/makepkg.conf
    # change default compression to zstd
    sed -i -r "s/^PKGEXT='.*'$/PKGEXT='.pkg.tar.zst'/" /etc/makepkg.conf

}
