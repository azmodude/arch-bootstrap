# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

Vagrant.configure("2") do |config|
  config.vm.define :archbox do |arch|
    arch.vm.box = "archlinux/archlinux"
    # enable ssh forwarding
    arch.ssh.forward_agent = true

#    arch.vm.synced_folder './', '/vagrant', type: 'rsync'
    # as we are using a GUI, modify VM to accomodate for that
    arch.vm.provider :virtualbox do |vb|
      disk_file = 'arch_install.vdi'
      vb.name = "arch"
      vb.gui = true
      vb.customize ["modifyvm", :id, "--vram", "64"]
      vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
      vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
      vb.customize ['createhd', '--filename', disk_file, '--size', 20 * 1024]
      vb.customize ['storageattach', :id, '--storagectl', 'IDE Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_file]
    end
    arch.vm.provider :libvirt do |lv|
      # lv.loader = '/usr/share/qemu/OVMF.fd'
      lv.memory ='1536'
      lv.video_type = 'qxl'
      lv.graphics_type ='spice'
      lv.keymap = 'de'
      lv.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
      lv.storage :file, :size => '40G', :type => 'qcow2', :bus => 'virtio', :device => 'vdb'

    end

    arch.vm.box_check_update = true
    arch.vm.provision "shell", inline: <<-SHELL
        pacman -Sy
        rm -rf /etc/pacman.d/gnupg
        # Work around Arch's keymgmt being anal sometimes
        pacman-key --init && pacman-key --populate archlinux && \
            pacman -Syw --noconfirm archlinux-keyring && \
            pacman --noconfirm -S archlinux-keyring
		pacman -S --noconfirm dialog bc
    SHELL
  end
end
