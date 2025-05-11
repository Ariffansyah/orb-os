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
# SECTION 4: BROWSER SETUP
# ==========================================
# Install Firefox as the default browser for Fedora GNOME
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Make sure we don't remove Firefox
    rpm-ostree install \
    firefox \
    firefox-langpacks \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 5: PACKAGE REMOVALS
# ==========================================
# Remove unwanted packages, but keep Firefox
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    htop \
    nvtop \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DEVELOPER TOOLS & UTILITIES
# ==========================================
# Install developer tools and additional utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
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
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 7: DESKTOP ENVIRONMENT
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
# SECTION 8: HOMEBREW SETUP
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
# SECTION 9: PROGRAMMING LANGUAGES
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
# SECTION 10: FASTFETCH SETUP
# ==========================================
# Ensure fastfetch is properly installed and configured
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install fastfetch
    rpm-ostree install fastfetch && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 11: NEOVIM INSTALLATION
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
# SECTION 12A: OSTREE REMOTE CONFIGURATION
# ==========================================
# Split the final configuration into smaller parts
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Create OSTree remote configuration for proper updates
    mkdir -p /etc/ostree/remotes.d && \
    echo '[remote "orb-os"]' > /etc/ostree/remotes.d/orb-os.conf && \
    echo "url=ostree-unverified-registry:ghcr.io/ariffansyah/orb-os" >> /etc/ostree/remotes.d/orb-os.conf && \
    echo "gpg-verify=false" >> /etc/ostree/remotes.d/orb-os.conf && \
    ostree container commit

# ==========================================
# SECTION 12B: FIRSTBOOT SCRIPT
# ==========================================
RUN mkdir -p /usr/libexec/orb-os && \
    echo '#!/bin/bash' > /usr/libexec/orb-os/firstboot.sh && \
    echo '' >> /usr/libexec/orb-os/firstboot.sh && \
    echo '# Set the correct origin for the current deployment' >> /usr/libexec/orb-os/firstboot.sh && \
    echo 'rpm-ostree origin referrer set ostree-unverified-registry:ghcr.io/ariffansyah/orb-os:latest' >> /usr/libexec/orb-os/firstboot.sh && \
    echo 'echo "Origin reference updated successfully"' >> /usr/libexec/orb-os/firstboot.sh && \
    chmod +x /usr/libexec/orb-os/firstboot.sh && \
    ostree container commit

# ==========================================
# SECTION 12C: SYSTEMD SERVICE
# ==========================================
RUN mkdir -p /usr/lib/systemd/system && \
    echo '[Unit]' > /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'Description=Set correct origin for orb-os' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'After=network-online.target' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'Wants=network-online.target' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'ConditionPathExists=!/var/lib/orb-os-firstboot-done' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo '' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo '[Service]' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'Type=oneshot' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'ExecStart=/usr/libexec/orb-os/firstboot.sh' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'ExecStartPost=/usr/bin/touch /var/lib/orb-os-firstboot-done' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'RemainAfterExit=yes' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo '' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo '[Install]' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    echo 'WantedBy=multi-user.target' >> /usr/lib/systemd/system/orb-os-firstboot.service && \
    ostree container commit

# ==========================================
# SECTION 12D: SERVICE CONFIGURATION
# ==========================================
RUN systemctl enable orb-os-firstboot.service && \
    systemctl enable gdm && \
    systemctl disable sddm || true && \
    systemctl disable cosmic-greeter || true && \
    systemctl set-default graphical.target && \
    systemctl enable brew-dir-fix.service || true && \
    systemctl enable brew-setup.service || true && \
    systemctl disable brew-upgrade.timer || true && \
    systemctl disable brew-update.timer || true && \
    systemctl disable waydroid-container.service || true && \
    systemctl --global enable podman.socket || true && \
    ostree container commit

# ==========================================
# SECTION 12E: ADDITIONAL UTILITIES
# ==========================================
RUN curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf || true && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh || true && \
    chmod +x /usr/bin/waydroid-choose-gpu || true && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf || true && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini || true && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini || true && \
    ostree container commit

# ==========================================
# SECTION 12F: REPO MANAGEMENT & FLATPAK
# ==========================================
RUN sed -i 's/stage/none/g' /etc/rpm-ostreed.conf || true && \
    find /etc/yum.repos.d/ -name '_copr_*.repo' -exec sed -i 's@enabled=1@enabled=0@g' {} \; || true && \
    # Disable other repositories for faster sync
    for repo in tailscale.repo charm.repo negativo17-fedora-multimedia.repo negativo17-fedora-steam.repo negativo17-fedora-rar.repo; do \
    if [ -f "/etc/yum.repos.d/$repo" ]; then \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/$repo; \
    fi \
    done || true && \
    # Setup Flatpak
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo || true && \
    ostree container commit

# ==========================================
# SECTION 12G: FIREFOX DEFAULT BROWSER SETUP
# ==========================================
RUN mkdir -p /usr/local/share/applications && \
    echo '[Default Applications]' > /usr/local/share/applications/mimeapps.list && \
    echo 'x-scheme-handler/http=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'x-scheme-handler/https=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'x-scheme-handler/chrome=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'text/html=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/x-extension-htm=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/x-extension-html=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/x-extension-shtml=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/xhtml+xml=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/x-extension-xhtml=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    echo 'application/x-extension-xht=firefox.desktop' >> /usr/local/share/applications/mimeapps.list && \
    ostree container commit

# ==========================================
# SECTION 12H: OSTREE CONFIGURATION & FINALIZATION
# ==========================================
RUN ostree remote delete orb-os 2>/dev/null || true && \
    ostree remote add --no-gpg-verify orb-os ostree-unverified-registry:ghcr.io/ariffansyah/orb-os && \
    # Finishing up
    if [ -x /usr/libexec/containerbuild/image-info ]; then /usr/libexec/containerbuild/image-info; fi && \
    if [ -x /usr/libexec/containerbuild/build-initramfs ]; then /usr/libexec/containerbuild/build-initramfs; fi && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit

# Copy override files at the end
COPY override /
