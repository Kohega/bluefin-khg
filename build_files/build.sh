#!/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

function echo_group() {
    local WHAT
    WHAT="$(
        basename "$1" .sh |
            tr "-" " " |
            tr "_" " "
    )"
    echo "::group:: == ${WHAT^^} =="
    "$1"
    echo "::endgroup::"
}

log() {
  echo "== $* =="
}


log "Starting building"
### Create root directory for hdd mount points 
mkdir /data

### Install packages
log "Installing apps"
echo_group /ctx/install_packages.sh

# Install RPMs
log "Installing apps from RPM"
cd /ctx/rpm
wget "https://litter.catbox.moe/2wd36xqfpvdpfvq8.rpm"
for rpm_file in ctx/rpm/*.rpm; do
    if [ -f "$rpm_file" ]; then
        dnf5 install -y "$rpm_file"
    fi
done
cd ../..

log "Allow Samba on home dirs"
setsebool -P samba_enable_home_dirs=1

log "Enable loading kernel modules"
setsebool -P domain_kernel_load_modules on

log "Enabling system services"
systemctl enable podman.socket syncthing@kohega.service zerotier-one.service sshd.service

log "Adding personal just recipes"
echo "import \"/usr/share/kohega/just/kohega.just\"" >>/usr/share/ublue-os/justfile

log "Rebuild initramfs"
echo_group /ctx/build-initramfs.sh

log "Post build cleanup"
echo_group /ctx/cleanup.sh

log "Build complete"
