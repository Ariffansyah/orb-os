FROM ghcr.io/ublue-os/cosmic-atomic-main:42

ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-cosmic}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-cosmic-atomic-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system /
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --experimental \
    --from repo=fedora \
    libusb1 \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    vulkan-loader \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    alsa-lib \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    gnutls \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glib2 \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    nspr \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    nss \
    nss-softokn \
    nss-softokn-freebl \
    nss-sysinit \
    nss-util \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    atk \
    at-spi2-atk \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libaom \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    gstreamer1 \
    gstreamer1-plugins-base \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libdecor \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libtirpc \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libuuid \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libblkid \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libmount \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cups-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libinput \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libopenmpt \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    llvm-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    zlib-ng-compat \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    fontconfig \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    pciutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libdrm \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cpp \
    libatomic \
    libgcc \
    libgfortran \
    libgomp \
    libobjc \
    libstdc++ \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libX11 \
    libX11-common \
    libX11-xcb \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libv4l \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    elfutils-libelf \
    elfutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glibc \
    glibc-common \
    glibc-all-langpacks \
    glibc-gconv-extra \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libxcrypt \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    SDL2 \
    || true && \
    rpm-ostree override remove \
    glibc32 \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git \
    vim \
    zsh \
    starship \
    ghostty \
    ptyxis \
    tmux \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    firefox \
    firefox-langpacks \
    htop \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git \
    discover-overlay \
    cpulimit \
    tailscale \
    lact \
    fastfetch \
    btop \
    fzf \
    zoxide \
    eza \
    vim \
    zsh \
    starship \
    zsh \
    zsh-autosuggestions \
    ghostty \
    ptyxis \
    tmux \
    unzip \
    cascadia-code-nf-fonts \
    cascadia-mono-nf-fonts \
    nerd-fonts \
    neovim \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    cosmic-desktop && \
    # Install gnome-software and gnome-disks
    rpm-ostree install \
    gnome-software \
    gnome-disk-utility \
    gparted \
    gnome-keyring NetworkManager-tui \
    NetworkManager-openvpn && \
    # We remove cosmic-store and replace it with gnome-software for better functionality
    rpm-ostree remove \
    cosmic-store || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    echo "Will install Homebrew inside /home/linuxbrew" && \
    touch /.dockerenv && \
    mkdir -p /var/home && \
    mkdir -p /var/roothome && \
    curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh && \
    chmod +x /tmp/brew-install && \
    /tmp/brew-install && \
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    fastfetch \
    nodejs \
    npm \
    java-latest-openjdk \
    golang \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# Add this after line 287 in a separate RUN block to ensure fastfetch is installed correctly
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Ensure fastfetch is properly installed from the main Fedora repositories
    rpm-ostree install \
    fastfetch \
    && /usr/libexec/build/clean.sh \
    && ostree container commit

# Also add this to verify and create symlinks if needed
RUN if [ ! -f /usr/bin/fastfetch ] && [ -f /usr/bin/fastfetch-bin ]; then \
    ln -s /usr/bin/fastfetch-bin /usr/bin/fastfetch; \
    fi && \
    if [ -f /usr/libexec/fancy-fastfetch ]; then \
    # Fix the shebang line if it's incorrect
    sed -i '1s|.*|#!/usr/bin/env bash|' /usr/libexec/fancy-fastfetch; \
    fi

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    python3 \
    python3-pip \
    python3-devel \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

### LINTING
## Verify final image and contents are correct.
COPY override /

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Service management
    systemctl enable lactd || true && \
    systemctl disable gdm || true && \
    systemctl disable sddm || true && \
    systemctl enable cosmic-greeter && \
    systemctl enable brew-dir-fix.service && \
    systemctl enable brew-setup.service && \
    systemctl disable brew-upgrade.timer && \
    systemctl disable brew-update.timer && \
    systemctl disable waydroid-container.service || true && \
    systemctl --global enable podman.socket && \
    # Adding good stuff
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh || true && \
    chmod +x /usr/bin/waydroid-choose-gpu || true && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini || true && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini || true && \
    # Configure OSTree remote for updates
    mkdir -p /etc/ostree && \
    ostree remote delete fedora-iot || true && \
    ostree remote delete ghcr-orb-os || true && \
    ostree remote add --no-gpg-verify ghcr-orb-os https://ghcr.io/ariffansyah/orb-os:latest && \
    echo "Configured OSTree remote for updates" && \
    # Configure rpm-ostree update behavior
    mkdir -p /etc/rpm-ostreed.conf.d/ && \
    echo -e "[Daemon]\nAutomaticUpdatePolicy=check" > /etc/rpm-ostreed.conf.d/automatic-updates.conf && \
    # Disabling copr for faster sync
    sed -i 's/stage/none/g' /etc/rpm-ostreed.conf || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-bazzite.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-bazzite-multilib.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-latencyflex.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-obs-vkcapture.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ycollet-audinux.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-rom-properties.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-webapp-manager.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_hhd-dev-hhd.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_che-nerd-fonts.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_mavit-discover-overlay.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_lizardbyte-beta.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_hikariknight-looking-glass-kvmfr.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_pgdev-ghostty.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_atim-starship.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_atim-heroic-games-launcher.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_trs-sod-swaylock-effects.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_alebastr-sway-extras.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_aeiro-nwg-shell.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/tailscale.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/charm.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-steam.repo || true && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-rar.repo || true && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    # Finishing stuff
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit

RUN bootc container lint
