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
RUN chmod +x /usr/libexec/containerbuild/*
RUN chmod +x /etc/systemd/system/*.service

# ==========================================
# SECTION 1: SYSTEM PACKAGE OVERRIDES
# ==========================================
# Override system packages with updates for better compatibility
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --experimental \
    --from repo=fedora \
    libusb1 \
    || true && \
    # Graphics and display overrides
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
    # Media and codec overrides
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    alsa-lib \
    gstreamer1 gstreamer1-plugins-base \
    libaom \
    libopenmpt \
    libv4l \
    || true && \
    # System library overrides
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
    # Compiler and runtime libraries
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cpp libatomic libgcc libgfortran libgomp libobjc libstdc++ \
    elfutils-libelf elfutils-libs \
    || true && \
    # Core system overrides
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glibc glibc-common glibc-all-langpacks glibc-gconv-extra \
    libxcrypt \
    SDL2 \
    || true && \
    # Remove unnecessary packages
    rpm-ostree override remove \
    glibc32 \
    nvtop \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 2: REPOSITORY SETUP
# ==========================================
# Add necessary repositories
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo \
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-lazygit.repo \
    https://copr.fedorainfracloud.org/coprs/atim/lazygit/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-lazygit-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_alternateved-eza.repo \
    https://copr.fedorainfracloud.org/coprs/alternateved/eza/repo/fedora-"${FEDORA_MAJOR_VERSION}"/alternateved-eza-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rpm-ostree install \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 3: CORE UTILITIES
# ==========================================
# Install basic terminal utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Terminal utilities
    git vim zsh starship tmux \
    eza \
    # Terminal emulators
    ghostty ptyxis \
    # File manager
    nautilus \
    # PostgreSQL CLI tools
    postgresql \
    # System utilities
    util-linux-user \
    util-linux \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 4: PACKAGE REMOVALS
# ==========================================
# Remove unwanted packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    htop \
    nvtop \
    firefox firefox-langpacks \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 5: DEVELOPER TOOLS & UTILITIES
# ==========================================
# Install developer tools and additional utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    unzip \ 
    wget \
    curl \
    # Productivity tools
    git fzf zoxide \
    btop fastfetch \
    # System utilities
    cpulimit \
    unzip \
    # Shells and terminal enhancers
    vim zsh starship zsh-autosuggestions \
    ghostty ptyxis tmux \
    # Fonts
    cascadia-code-nf-fonts cascadia-mono-nf-fonts \
    # Editors
    neovim \
    lazygit \
    # Qt5 development packages
    qt5-qtbase-devel qt5-qttools qt5-qtdeclarative-devel qt5-qtquickcontrols2-devel qt5-qtmultimedia-devel qt5-qtwebsockets-devel \
    # Qt6 development packages
    qt6-qtbase-devel qt6-qttools qt6-qtdeclarative-devel qt6-qtquick3d-devel qt6-qtmultimedia-devel qt6-qtwebsockets-devel \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DESKTOP ENVIRONMENT
# ==========================================
# Install GNOME desktop environment and utilities, and only RPM-packaged extensions
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
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
    && /usr/libexec/containerbuild/cleanup.sh \
    && ostree container commit

RUN rpm-ostree install unzip wget curl && \
    /usr/libexec/containerbuild/cleanup.sh

# ==========================================
# SECTION 7: HOMEBREW SETUP
# ==========================================
# Install Homebrew package manager
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    echo "Will install Homebrew inside /home/linuxbrew" && \
    touch /.dockerenv && \
    mkdir -p /var/home && \
    mkdir -p /var/roothome && \
    curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh && \
    chmod +x /tmp/brew-install && \
    /tmp/brew-install && \
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 8: PROGRAMMING LANGUAGES
# ==========================================
# Install programming languages and development tools
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # JavaScript/Node.js
    nodejs npm \
    # Java
    java-latest-openjdk \
    # Go
    golang \
    # Python
    python3 python3-pip python3-devel \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 9: FINAL CONFIGURATION
# ==========================================
# Copy override files and configure the system
COPY override /

RUN systemctl enable set-hostname.service

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Service management
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
    # Enabling just files
    echo "import \"/usr/share/ublue-os/just/80-orb.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/81-orb-fix.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-orb-extensions.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/84-orb-config.just\"" >> /usr/share/ublue-os/justfile && \
    # Adding good stuff
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh && \
    chmod +x /usr/bin/waydroid-choose-gpu && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini && \
    # Disabling copr and other repos for faster sync
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
    # Finishing up
    /usr/libexec/containerbuild/image-info && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
