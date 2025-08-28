#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Enable Copr repos"

COPR_REPOS=(
    zliced13/YACR
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

log "Install layered applications"

# Layered Applications
LAYERED_PACKAGES=(
    aria2c
    syncthing
    filezilla
    firefox
    firefox-langpacks
    gh
    usbmuxd
    kodi
    kodi-inputstream-adaptive
    qbittorrent
    discord
    bleachbit
    nemo
    rofi-wayland
)
dnf5 install --setopt=install_weak_deps=False --skip-unavailable --allowerasing -y "${LAYERED_PACKAGES[@]}"

log "Disable Copr repos as we do not need it anymore"

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

log "Installing RPM packages"


log "Installing ZeroTier"
# Add ZeroTier GPG key
curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier

# Add ZeroTier repository
cat << 'EOF' | tee /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=http://download.zerotier.com/redhat/fc/42
enabled=1
gpgcheck=0
EOF

# Install ZeroTier
dnf install -y zerotier-one

# Remove repos
rm /etc/yum.repos.d/zerotier.repo -f
