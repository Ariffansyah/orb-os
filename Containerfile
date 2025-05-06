FROM ghcr.io/ublue-os/cosmic-atomic-main:42

# Define build arguments
ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-cosmic}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-cosmic-atomic-main}"
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
    || true && \
    /usr/libexec/build/clean.sh && \
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
    /usr/libexec/build/clean.sh && \
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
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# Install Mesa drivers and multimedia components from Fedora repositories
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install standard Fedora Mesa packages
    rpm-ostree install \
    mesa-dri-drivers \
    mesa-dri-drivers.i686 \
    mesa-libGL \
    mesa-libEGL \
    mesa-libgbm \
    mesa-libglapi \
    mesa-vulkan-drivers \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    xorg-x11-drv-libinput \
    xorg-x11-server-Xwayland \
    # Install PipeWire and related packages
    pipewire \
    pipewire-alsa \
    pipewire-gstreamer \
    pipewire-jack-audio-connection-kit \
    pipewire-jack-audio-connection-kit-libs \
    pipewire-libs \
    pipewire-pulseaudio \
    pipewire-utils \
    pipewire-plugin-libcamera \
    # Install Bluetooth support
    bluez \
    bluez-obexd \
    bluez-cups \
    bluez-libs \
    # Enable RPM Fusion repos temporarily for multimedia components
    && sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/rpmfusion-*.repo 2>/dev/null || true \
    && rpm-ostree install \
    libbluray \
    libbluray-utils \
    # Disable RPM Fusion repos again
    && sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion-*.repo 2>/dev/null || true \
    && /usr/libexec/build/clean.sh \
    && ostree container commit

# ==========================================
# SECTION 4: PACKAGE REMOVALS
# ==========================================
# Remove unwanted packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    firefox firefox-langpacks \
    htop \
    || true && \
    /usr/libexec/build/clean.sh && \
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
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DESKTOP ENVIRONMENT
# ==========================================
# Install COSMIC desktop environment and utilities
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
    /usr/libexec/build/clean.sh && \
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
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 9: FASTFETCH SETUP
# ==========================================
# Ensure fastfetch is properly installed and configured
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install fastfetch
    rpm-ostree install fastfetch && \
    /usr/libexec/build/clean.sh && \
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
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 11: FINAL CONFIGURATION
# ==========================================
# Copy override files and configure the system
COPY override /

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Fix missing user accounts for cosmic-greeter and greetd
    grep -E '^greetd:' /usr/etc/passwd >> /etc/passwd || true && \
    grep -E '^cosmic-greeter:' /usr/etc/passwd >> /etc/passwd || true && \
    grep -E '^greetd:' /usr/etc/group >> /etc/group || true && \
    grep -E '^cosmic-greeter:' /usr/etc/group >> /etc/group || true && \
    # Ensure proper graphics boot by setting graphical target as default
    systemctl set-default graphical.target && \
    # Make sure existing display managers are disabled to avoid conflicts
    systemctl disable gdm.service gdm.socket || true && \
    systemctl disable sddm.service sddm.socket || true && \
    # Create a directory for cosmic-greeter service overrides
    mkdir -p /etc/systemd/system/cosmic-greeter.service.d && \
    # Create optimized cosmic-greeter service override with fixed dependencies
    echo -e '[Unit]\nDescription=COSMIC Desktop Greeter\nBefore=graphical.target\nAfter=multi-user.target\nAfter=systemd-user-sessions.service\nAfter=plymouth-quit.service\nConflicts=gdm.service sddm.service\n\n[Service]\nType=simple\nExecStartPre=/bin/sleep 1\nRestart=always\nRestartSec=1\n\n[Install]\nWantedBy=graphical.target' > /etc/systemd/system/cosmic-greeter.service.d/override.conf && \
    # Create a first-boot service to ensure cosmic-greeter users exist
    mkdir -p /usr/local/bin && \
    echo '#!/bin/bash\n# Ensure required users and groups exist at first boot\nif ! grep -q "^cosmic-greeter:" /etc/passwd; then\n    grep -E "^cosmic-greeter:" /usr/etc/passwd >> /etc/passwd || true\nfi\nif ! grep -q "^greetd:" /etc/passwd; then\n    grep -E "^greetd:" /usr/etc/passwd >> /etc/passwd || true\nfi\nif ! grep -q "^cosmic-greeter:" /etc/group; then\n    grep -E "^cosmic-greeter:" /usr/etc/group >> /etc/group || true\nfi\nif ! grep -q "^greetd:" /etc/group; then\n    grep -E "^greetd:" /usr/etc/group >> /etc/group || true\nfi' > /usr/local/bin/cosmic-users-setup && \
    chmod +x /usr/local/bin/cosmic-users-setup && \
    # Create a systemd service for the first boot script
    mkdir -p /etc/systemd/system && \
    echo '[Unit]\nDescription=COSMIC Users Setup\nBefore=cosmic-greeter.service\nBefore=display-manager.service\nAfter=local-fs.target\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/cosmic-users-setup\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/cosmic-users-setup.service && \
    systemctl enable cosmic-users-setup.service && \
    # Create a cosmic-recovery service to ensure desktop boots reliably
    echo '#!/bin/bash\n# Check if cosmic-greeter is running, if not try to restart it\nif ! systemctl is-active cosmic-greeter > /dev/null; then\n    echo "cosmic-greeter not active, attempting recovery..."\n    # Wait a moment for any race conditions to settle\n    sleep 5\n    # Ensure user accounts exist\n    if ! grep -q "^cosmic-greeter:" /etc/passwd; then\n        grep -E "^cosmic-greeter:" /usr/etc/passwd >> /etc/passwd || true\n    fi\n    if ! grep -q "^greetd:" /etc/passwd; then\n        grep -E "^greetd:" /usr/etc/passwd >> /etc/passwd || true\n    fi\n    if ! grep -q "^cosmic-greeter:" /etc/group; then\n        grep -E "^cosmic-greeter:" /usr/etc/group >> /etc/group || true\n    fi\n    if ! grep -q "^greetd:" /etc/group; then\n        grep -E "^greetd:" /usr/etc/group >> /etc/group || true\n    fi\n    \n    # Restart the greeter service\n    systemctl restart cosmic-greeter\nfi' > /usr/local/bin/cosmic-recovery && \
    chmod +x /usr/local/bin/cosmic-recovery && \
    # Create a systemd service for the recovery script
    echo '[Unit]\nDescription=COSMIC Desktop Recovery Service\nAfter=multi-user.target\nAfter=network.target\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/cosmic-recovery\nRemainAfterExit=yes\n\n[Install]\nWantedBy=graphical.target' > /etc/systemd/system/cosmic-recovery.service && \
    systemctl enable cosmic-recovery.service && \
    # Ensure cosmic-greeter is properly registered as a display manager
    mkdir -p /etc/systemd/system/display-manager.service.d && \
    echo '[Unit]\nDescription=COSMIC Display Manager\nConflicts=gdm.service sddm.service\n\n[Service]\nExecStart=\nExecStart=/usr/bin/cosmic-greeter' > /etc/systemd/system/display-manager.service.d/cosmic-override.conf && \
    ln -sf /usr/lib/systemd/system/cosmic-greeter.service /etc/systemd/system/display-manager.service || true && \
    # Create helper script for fixing boot issues
    mkdir -p /usr/local/bin && \
    echo '#!/bin/bash\necho "Fixing COSMIC GUI boot issues..."\nsystemctl set-default graphical.target\nsystemctl disable gdm sddm || true\nsystemctl enable cosmic-greeter cosmic-users-setup cosmic-recovery\nsystemctl restart cosmic-greeter' > /usr/local/bin/fix-cosmic-gui && \
    chmod +x /usr/local/bin/fix-cosmic-gui && \
    # Enable COSMIC service and other necessary services
    systemctl enable cosmic-greeter && \
    systemctl enable lactd || true && \
    systemctl enable brew-dir-fix.service && \
    systemctl enable brew-setup.service && \
    systemctl disable brew-upgrade.timer && \
    systemctl disable brew-update.timer && \
    systemctl --global enable podman.socket && \
    # Add configuration files and utilities
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
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
    # Finishing up
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
