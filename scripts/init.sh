#!/usr/bin/env bash

# packages that need to be installed
arch_packages="linux nano vi cloud-init cloud-utils syslinux openssh"
# systemd services that need to be enabled
system_services="systemd-networkd sshd cloud-init-local cloud-init cloud-config cloud-final"
# kernel modules that get added to /etc/mkinitcpio
initcpio_modules="virtio virtio_pci virtio_blk virtio_net virtio_ring"
# block device parition with root fs, minus the /dev/ part
root_part="vda1"

help_and_exit() {
  cat 1>&2 << EOF
init.sh
Initialize a new Arch Linux install for the cloud. This runs in the chroot,
Once, as root.

This installs the boot loader, configures disk modules for initcpio, and enables
systemd services. There are no options or parameters, this script will delete
itself once done.

EOF
  exit 4
}

message(){
  echo "init.sh: ${@}"
}

submsg(){
  echo "[+]	${@}"
}

exit_with_error(){
  echo 1>&2 "init.sh: ERROR: ${2}"
  exit ${1}
}

warn(){
  echo 1>&2 "init.sh: WARN: ${@}"
}

install_packages() {
  submsg "Installing/Updated Base packages"
  pacman -Syu ${arch_packages}
  return $?
}

install_syslinux() {
  submsg "Configuring Syslinux Bootloader"
  sed -i s/sda3/${root_part}/g /boot/syslinux/syslinux.cfg
  syslinux-install_update -i -a -m
  return $?
}

enable_services() {
  submsg "Enabling Systemd Units"
  systemctl enable ${system_services}
  return $?
}

config_initcpio() {
  submsg "Updating mkinicpio.conf"
  sed -i s/"MODULES=()"/"MODULES=(${initcpio_modules})"/g /etc/mkinitcpio.conf
  return $?
}

main() {
  local -i exit_code=0
  [ $1 == "help" || $1 == "--help" ] && help_and_exit
  message "Initalizing..."
  install_packages || exit_code+=1
  install_syslinux || exit_code+=1
  enable_services  || exit_code+=1
  config_initcpio  || exit_code+=1
  message "Done!"
  [ $exit_code -ne 0 ] && exit_with_error 1 "There where errrors, check above output"
  rm ${0} #script deletes itself when done
}

main "${@}"
