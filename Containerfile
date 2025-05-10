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
# Override system packages with updates for better compatibility
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Base system overrides
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
    # Add COPR repositories
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo \
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
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
    # Terminal emulators
    ghostty ptyxis \
    # File manager
    nautilus \
    # PostgreSQL CLI tools
    postgresql \
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
    firefox firefox-langpacks \
    htop \
    nvtop \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 5: DEVELOPER TOOLS & UTILITIES
# ==========================================
# Install developer tools and additional utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Productivity tools
    git fzf zoxide eza \
    btop fastfetch \
    # System utilities
    discover-overlay cpulimit tailscale lact \
    unzip \
    # Shells and terminal enhancers
    vim zsh starship zsh-autosuggestions \
    ghostty ptyxis tmux \
    # Fonts
    cascadia-code-nf-fonts cascadia-mono-nf-fonts nerd-fonts \
    # Editors
    neovim \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DESKTOP ENVIRONMENT
# ==========================================
# Install GNOME desktop environment and utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    gnome-shell gnome-session gnome-terminal gnome-control-center \
    gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator \
    gnome-backgrounds gnome-themes-extra gnome-shell-extension-dash-to-dock \
    gdm && \
    # Install gnome-software and gnome-disks
    rpm-ostree install \
    gnome-software \
    gnome-disk-utility \
    gparted \
    gnome-keyring NetworkManager-tui \
    NetworkManager-openvpn && \
    # Remove any COSMIC packages if they exist
    rpm-ostree remove \
    cosmic-desktop cosmic-greeter cosmic-store || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

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
# SECTION 9: FASTFETCH SETUP
# ==========================================
# Ensure fastfetch is properly installed and configured
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install fastfetch
    rpm-ostree install fastfetch && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 10: NEOVIM INSTALLATION
# ==========================================
# Ensure neovim is properly installed
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install neovim specifically
    rpm-ostree install neovim && \
    # Verify the installation
    rpm -q neovim && \
    which nvim || echo "Neovim not found in PATH" && \
    # Clean up
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 11: FINAL CONFIGURATION
# ==========================================
# Copy override files and configure the system
COPY override /

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Service management
    systemctl enable lactd || true && \
    systemctl enable gdm && \
    systemctl disable sddm || true && \
    systemctl disable cosmic-greeter || true && \
    systemctl set-default graphical.target && \
    systemctl enable brew-dir-fix.service && \
    systemctl enable brew-setup.service && \
    systemctl disable brew-upgrade.timer && \
    systemctl disable brew-update.timer && \
    systemctl disable waydroid-container.service || true && \
    systemctl --global enable podman.socket && \
    # Add configuration files and utilities
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh || true && \
    chmod +x /usr/bin/waydroid-choose-gpu || true && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini || true && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini || true && \
    # Disable COPR repositories to speed up syncing
    sed -i 's/stage/none/g' /etc/rpm-ostreed.conf || true && \
    find /etc/yum.repos.d/ -name '_copr_*.repo' -exec sed -i 's@enabled=1@enabled=0@g' {} \; && \
    # Disable other repositories for faster sync
    for repo in tailscale.repo charm.repo negativo17-fedora-multimedia.repo negativo17-fedora-steam.repo negativo17-fedora-rar.repo; do \
    if [ -f "/etc/yum.repos.d/$repo" ]; then \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/$repo; \
    fi \
    done && \
    # Setup Flatpak
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    # Install Zen Browser via Flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install -y flathub org.mozilla.firefox || true && \
    # Finishing up
    if [ -x /usr/libexec/containerbuild/image-info ]; then /usr/libexec/containerbuild/image-info; fi && \
    if [ -x /usr/libexec/containerbuild/build-initramfs ]; then /usr/libexec/containerbuild/build-initramfs; fi && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
