#!/usr/bin/env bash

## CONFIG ##
# User config placed in chroot
local_config="/etc/cloud/init.local"
# packages that need to be installed
arch_packages="cloud-init cloud-utils syslinux openssh mkinitcpio ${KERNEL}"
# systemd services that need to be enabled
system_services="systemd-networkd sshd cloud-init-local cloud-init cloud-config cloud-final"
# kernel modules that get added to /etc/mkinitcpio
initcpio_modules="virtio virtio_pci virtio_blk virtio_net virtio_ring"
# block device parition with root fs, minus the /dev/ part
root_part="vda1"
## /CONFIG ##

help_and_exit() {
  cat 1>&2 << EOF
init.sh
Initialize a new Arch Linux install for the cloud. This runs in the chroot,
Once, as root.

This installs the boot loader, configures disk modules for initcpio, and enables
systemd services. There are no options or parameters.

reads additional config from ${local_config}

EOF
  exit 4
}

message(){
  echo "init.sh: ${@}"
}

submsg(){
  echo "==> ${@}"
}

exit_with_error(){
  echo 1>&2 "init.sh: ERROR: ${2}"
  exit ${1}
}

warn(){
  echo 1>&2 "init.sh: WARN: ${@}"
}

parse_environment(){
  # parse a key=pair shell enviroment file. NOTE all keys will be made UPPERCASE
  # variables. in parent script.

  local infile="${@}"
  local safe_config=$(mktemp)
  local key=""
  local value=""
  
  [ -f ${infile} ] || return 2 # infile is not a file
  # Now we have an array of file lines
  readarray file_lines < "${infile}" || return 1 # error proccessing

  for line in ${file_lines[@]};do
    # Remove comments
    [ ${line} == "#" ]; continue
    line=$(cut -d "#" -f 1 <<< ${line} )

    # Split key and value from lines
    key=$(cut -d "=" -f 1 <<< ${line} )
    value=$(cut -d "=" -f 2 <<< ${line} )

    # Parse key. Make the Key uppercase, remove spaces and all non-alphanumeric
    # characters
    key=$(key^^)
    key=${key// /}
    key=$(tr -cd "[:alnum:]" <<< $key)

    # Parse value. Remove anything that can escape a variable and run code.
    value=$(tr -d ";|&()" <<< $value )

    # Zero check. If after cleaning either the key or value is null, then
    # write nothing
    [ -z $key ] && continue
    [ -z $value ] && continue

    # write sanitized values to temp file
    echo "${key}=${value}" >> ${safe_config}
  done

  #Now, we can import the cleaned config and then delete it.
  source ${safe_config}
  rm $(safe_config)
}

install_packages() {
  submsg "Installing/Updated Base packages"
  pacman --noconfirm -Syu ${arch_packages} ${ADDITIONAL_PACKAGES}
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
  systemctl enable ${system_services} ${SYSTEM_SERVICES}
  return $?
}

config_initcpio() {
  local -i exit_n=0
  submsg "Updating mkinicpio.conf"
  sed -i s/"MODULES=()"/"MODULES=(${initcpio_modules})"/g /etc/mkinitcpio.conf || exit_n+=1
  mkinitcpio -p ${KERNEL} || exit_n+=1
  return ${exit_n}
}

main() {
  local -i exit_code=0
  [ $1 == "help" || $1 == "--help" ] && help_and_exit
  message "Initalizing..."
  [ -f "${local_config}" ] && parse_environment "${local_config}" || warn "couldn't read ${local_config}"
  install_packages || exit_code+=1
  install_syslinux || exit_code+=1
  enable_services  || exit_code+=1
  config_initcpio  || exit_code+=1
  message "Done!"
  [ $exit_code -ne 0 ] && exit_with_error 1 "There where errrors, check above output"
}

main "${@}"
