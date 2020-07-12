#!/bin/bash

sudo INSTALL_DISK=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3-0-4 ROOT_PASSWORD=test LUKS_PASSPHRASE=test DISK_LAYOUT=btrfs HOSTNAME_FQDN=test.azmo.ninja SWAP_SIZE=2 /vagrant/arch_install.sh
