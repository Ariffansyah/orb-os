ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fedora}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG JUPITER_FIRMWARE_VERSION="${JUPITER_FIRMWARE_VERSION:-jupiter-20241205.1}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

FROM ghcr.io/ublue-os/base-main:${FEDORA_MAJOR_VERSION} AS orb-os

ARG IMAGE_NAME="${IMAGE_NAME:-orb-os}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fedora}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG JUPITER_FIRMWARE_VERSION="${JUPITER_FIRMWARE_VERSION:-jupiter-20241205.1}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG OSTREE_REMOTE="${OSTREE_REMOTE:-ostree-unverified-registry:ghcr.io/ariffansyah/orb-os:latest}"

COPY system /

# Setup Copr repos for Cosmic Desktop
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    if [[ "${FEDORA_MAJOR_VERSION}" == "rawhide" ]]; then \
    curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-rawhide/ryanabx-cosmic-epoch-fedora-rawhide.repo \
    ; else curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-$(rpm -E %fedora)/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo \
    ; fi && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install standard Fedora kernel
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree cliwrap install-to-root / && \
    echo "Will install standard Fedora kernel" && \
    rpm-ostree install \
    kernel \
    kernel-core \
    kernel-modules && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install and configure Cosmic DE
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ryanabx-cosmic.repo && \
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
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ryanabx-cosmic.repo && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    firefox \
    firefox-langpacks \
    htop \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install additional packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git \
    fastfetch \
    btop \
    fzf \
    zoxide \
    eza \
    vim \
    zsh \
    starship \
    zsh-autosuggestions \
    ghostty \
    ptyxis \
    tmux \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Homebrew
# For some reason some devices don't get homebrew installed on their machine when rebasing.
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

# Install WinApps dependencies
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    podman-compose \
    dialog \
    nmap-ncat \
    xfreerdp \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Finalize
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Create required directories
    mkdir -p /usr/share/ublue-os/packages && \
    mkdir -p /usr/share/ublue-os/just && \
    # Service management
    systemctl disable gdm || true && \
    systemctl disable sddm || true && \
    systemctl enable cosmic-greeter && \
    systemctl enable brew-dir-fix.service || true && \
    systemctl enable brew-setup.service || true && \
    systemctl disable brew-upgrade.timer || true && \
    systemctl disable brew-update.timer || true && \
    systemctl --global enable podman.socket || true && \
    # Enabling just files
    echo "# Orb OS customizations" >> /usr/share/ublue-os/justfile || true && \
    # Configure ostree remote
    echo "Setting ostree remote to ${OSTREE_REMOTE}" && \
    mkdir -p /usr/etc/ostree/remotes.d && \
    echo "[remote \"orb-os\"]" > /usr/etc/ostree/remotes.d/orb-os.conf && \
    echo "url=ostree-unverified-registry:ghcr.io/ariffansyah/orb-os:latest" >> /usr/etc/ostree/remotes.d/orb-os.conf && \
    echo "gpg-verify=false" >> /usr/etc/ostree/remotes.d/orb-os.conf && \
    echo "tls-permissive=true" >> /usr/etc/ostree/remotes.d/orb-os.conf && \
    # Disabling copr for faster sync
    sed -i 's/stage/none/g' /etc/rpm-ostreed.conf || true && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    # Finishing stuff
    /usr/libexec/containerbuild/image-info && \
    /usr/libexec/containerbuild/build-initramfs && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
