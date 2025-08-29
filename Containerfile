FROM scratch AS ctx
COPY build_files /

# Bluefin base
FROM ghcr.io/ublue-os/bluefin:stable
COPY system_files /
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=GITHUB_TOKEN \

    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/LatencyFleX \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        lizardbyte/stable; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade scx-scheds" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter*" && \
    /ctx/cleanup

# Install Steam & Lutris, plus supporting packages
# Downgrade ibus to fix an issue with the Steam keyboard
    dnf5 -y swap \
    --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite \
        ibus ibus && \
    dnf5 versionlock add \
        ibus && \
    dnf5 -y install \
        gamescope.x86_64 \
        gamescope-libs.x86_64 \
        gamescope-libs.i686 \
        gamescope-shaders \
        umu-launcher \
        dbus-x11 \
        xdg-user-dirs \
        gobject-introspection \
        libFAudio.x86_64 \
        libFAudio.i686 \
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        libobs_vkcapture.x86_64 \
        libobs_glcapture.x86_64 \
        libobs_vkcapture.i686 \
        libobs_glcapture.i686 \
        VK_hdr_layer && \
    dnf5 -y --setopt=install_weak_deps=False install \
        steam \
        lutris && \
    dnf5 -y remove \
        gamemode && \
    /ctx/ghcurl "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" --retry 3 -Lo /usr/bin/winetricks && \
    chmod +x /usr/bin/winetricks && \
    /ctx/build.sh && \

    ostree container commit

RUN bootc container lint