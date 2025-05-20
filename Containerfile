FROM ghcr.io/ublue-os/base-main:42 as ctx

# Expose /usr/libexec for build context
# No commands are needed, just use the system files

FROM ghcr.io/ublue-os/base-main:42

# Define build arguments
ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-gnome}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

# Copy system files
COPY system /

# ==========================================
# SECTION 1: SYSTEM PACKAGE OVERRIDES
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree override replace \
    --experimental \
    --from repo=fedora \
    libusb1 \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    vulkan-loader \
    libdrm \
    libdecor \
    atk \
    at-spi2-atk \
    libX11 libX11-common libX11-xcb \
    libinput \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    alsa-lib \
    gstreamer1 gstreamer1-plugins-base \
    libaom \
    libopenmpt \
    libv4l \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    gnutls \
    glib2 \
    nspr \
    nss nss-softokn nss-softokn-freebl nss-sysinit nss-util \
    libtirpc \
    libuuid \
    libblkid \
    libmount \
    cups-libs \
    llvm-libs \
    zlib-ng-compat \
    fontconfig \
    pciutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cpp libatomic libgcc libgfortran libgomp libobjc libstdc++ \
    elfutils-libelf elfutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glibc glibc-common glibc-all-langpacks glibc-gconv-extra \
    libxcrypt \
    SDL2 \
    || true && \
    rpm-ostree override remove \
    glibc32 \
    nvtop \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 2: REPOSITORY SETUP
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo \
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rpm-ostree install \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 3: CORE UTILITIES
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree install \
    git vim zsh starship tmux \
    ghostty ptyxis \
    nautilus \
    postgresql \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 4: PACKAGE REMOVALS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree override remove \
    ublue-os-update-services \
    htop \
    nvtop \
    firefox firefox-langpacks \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 5: DEVELOPER TOOLS & UTILITIES
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree install \
    unzip \ 
    wget \
    curl \
    git fzf zoxide \
    btop fastfetch \
    cpulimit \
    unzip \
    vim zsh starship zsh-autosuggestions \
    ghostty ptyxis tmux \
    cascadia-code-nf-fonts cascadia-mono-nf-fonts \
    neovim \
    qt-creator \
    qt5-qtbase-devel qt5-qttools qt5-qtdeclarative-devel qt5-qtquickcontrols2-devel qt5-qtmultimedia-devel qt5-qtwebsockets-devel \
    qt6-qtbase-devel qt6-qttools qt6-qtdeclarative-devel qt6-qtquick3d-devel qt6-qtmultimedia-devel qt6-qtwebsockets-devel \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DESKTOP ENVIRONMENT
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree install \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    gnome-control-center \
    gnome-tweaks \
    gnome-extensions-app \
    gnome-shell-extension-appindicator \
    gnome-backgrounds \
    gnome-themes-extra \
    gdm \
    gnome-software \
    gnome-disk-utility \
    gparted \
    gnome-keyring \
    NetworkManager-tui \
    NetworkManager-openvpn \
    && /ctx/usr/libexec/containerbuild/cleanup.sh \
    && ostree container commit

RUN --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree install unzip wget curl && \
    /ctx/usr/libexec/containerbuild/cleanup.sh

# ==========================================
# SECTION 7: HOMEBREW SETUP
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    echo "Will install Homebrew inside /home/linuxbrew" && \
    touch /.dockerenv && \
    mkdir -p /var/home && \
    mkdir -p /var/roothome && \
    curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh && \
    chmod +x /tmp/brew-install && \
    /tmp/brew-install && \
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 8: PROGRAMMING LANGUAGES
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    rpm-ostree install \
    nodejs npm \
    java-latest-openjdk \
    golang \
    python3 python3-pip python3-devel \
    || true && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 9: FINAL CONFIGURATION
# ==========================================
COPY override /

RUN --mount=type=bind,from=ctx,source=/usr/libexec,target=/ctx/usr/libexec \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    systemctl enable lactd || true && \
    systemctl enable gdm && \
    systemctl disable sddm || true && \
    systemctl disable cosmic-greeter || true && \
    systemctl enable orb-os-firstboot.service && \
    systemctl set-default graphical.target && \
    systemctl enable brew-dir-fix.service || true && \
    systemctl enable brew-setup.service || true && \
    systemctl disable brew-upgrade.timer || true && \
    systemctl disable brew-update.timer || true && \
    systemctl disable waydroid-container.service || true && \
    systemctl --global enable podman.socket && \
    echo "import \"/usr/share/ublue-os/just/80-orb.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/81-orb-fix.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-orb-extensions.just\"" >> /usr/share/ublue-os/justfile && \
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh && \
    chmod +x /usr/bin/waydroid-choose-gpu && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini && \
    for repo in \
    tailscale.repo \
    charm.repo \
    negativo17-fedora-multimedia.repo \
    negativo17-fedora-steam.repo \
    negativo17-fedora-rar.repo; \
    do \
    if [ -f "/etc/yum.repos.d/$repo" ]; then \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/$repo; \
    fi; \
    done && \
    find /etc/yum.repos.d/ -name '_copr_*.repo' -exec sed -i 's@enabled=1@enabled=0@g' {} \; && \
    sed -i 's/stage/none/g' /etc/rpm-ostreed.conf && \
    echo "orb" > /etc/hostname && \
    /ctx/usr/libexec/containerbuild/image-info && \
    /ctx/usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
