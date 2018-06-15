# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

Vagrant.configure("2") do |config|
  config.vm.define :archbox do |arch|
    arch.vm.box = "archlinux/archlinux"
    # enable ssh forwarding
    arch.ssh.forward_agent = true
    # as we are using a GUI, modify VM to accomodate for that
    arch.vm.provider :virtualbox do |vb|
      vb.name = "arch"
      vb.gui = true
      vb.customize ["modifyvm", :id, "--vram", "64"]
      vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
      vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    end
    arch.vm.provider :libvirt do |lv|
      lv.memory ='1536'
      lv.video_type = 'qxl'
      lv.graphics_type ='spice'
      lv.keymap = 'de'
      lv.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
      lv.storage :file, :size => '40G', :type => 'qcow2', :bus => 'virtio', :device => 'vdb'
    end

    arch.vm.box_check_update = true
    arch.vm.provision "shell", inline: <<-SHELL
		pacman -S --noconfirm dialog bc
    SHELL
  end
end
