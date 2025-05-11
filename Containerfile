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
# SECTION 2: SYSTEM PACKAGE OVERRIDES
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
# SECTION 3: REPOSITORY SETUP
# ==========================================
# Add necessary repositories
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo \
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rpm-ostree install \
    firefox firefox-langpacks \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 4: CORE UTILITIES
# ==========================================
# Install basic terminal utilities
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git vim zsh starship tmux \
    ghostty ptyxis \
    nautilus \
    postgresql \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 5: PACKAGE REMOVALS
# ==========================================
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
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git fzf zoxide \
    btop fastfetch \
    cpulimit \
    unzip \
    vim zsh starship zsh-autosuggestions \
    ghostty ptyxis tmux \
    cascadia-code-nf-fonts cascadia-mono-nf-fonts \
    neovim \
    firefox firefox-langpacks \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 7: DESKTOP ENVIRONMENT
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    gnome-shell gnome-session gnome-terminal gnome-control-center \
    gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator \
    gnome-backgrounds gnome-themes-extra \
    gnome-shell-extension-dash-to-dock \
    gdm && \
    rpm-ostree install \
    gnome-software \
    gnome-disk-utility \
    gparted \
    gnome-keyring NetworkManager-tui \
    NetworkManager-openvpn && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# ==========================================
# SECTION 12.5: FLATPAK SETUP AND INSTALLATION
# ==========================================
COPY flatpaks /tmp/flatpaks

RUN set -e && \
    mkdir -p /etc/flatpak/remotes.d /root/.cache/dconf /var/tmp && \
    chmod 1777 /var/tmp && \
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install --noninteractive flathub com.mattjakeman.ExtensionManager && \
    grep -v "com.mattjakeman.ExtensionManager" /tmp/flatpaks > /tmp/remaining-flatpaks && \
    grep -v "com.obsproject.Studio.Plugin.GStreamerVaapi" /tmp/remaining-flatpaks > /tmp/filtered-flatpaks && \
    cat /tmp/filtered-flatpaks | while read -r line; do \
    if [ -n "$line" ]; then \
    echo "Installing $line" && \
    flatpak install --noninteractive flathub $line || echo "Failed to install $line, continuing..."; \
    fi; \
    done && \
    rm -f /tmp/flatpaks /tmp/remaining-flatpaks /tmp/filtered-flatpaks
