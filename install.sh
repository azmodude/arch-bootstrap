#!/bin/bash

sudo INSTALL_DISK=vdb ROOT_PASSWORD=test LUKS_PASSPHRASE=test DISK_LAYOUT=btrfs HOSTNAME_FQDN=test.azmo.ninja SWAP_SIZE=16 /vagrant/arch_install.sh
