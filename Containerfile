FROM ghcr.io/ublue-os/base-main:42

# Define build arguments
ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-hyprland}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-fedora-kinoite}"
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
    # Add Hyprland COPR repository
    curl -Lo /etc/yum.repos.d/_copr_solopasha-hyprland.repo \
    https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-"${FEDORA_MAJOR_VERSION}"/solopasha-hyprland-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    # Add RPM Fusion repositories
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 3: HYPRLAND & DEPENDENCIES INSTALLATION
# ==========================================
# Install Hyprland and dependencies based on the hyprdots repository
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Core Hyprland packages
    hyprland \
    cliphist \
    xdg-desktop-portal-hyprland \
    swww \
    grimblast \
    # WM utilities
    wl-clipboard \
    go \
    gtk3-devel \
    xdg-utils \
    swappy \
    rust \
    cargo \
    # Fonts and themes
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    # Audio and sensors
    pamixer \
    alsa-ucm \
    alsa-firmware \
    alsa-sof-firmware \
    lm_sensors \
    cava \
    # Bluetooth
    bluez \
    bluez-tools \
    blueman \
    # Network
    NetworkManager-wifi \
    network-manager-applet \
    # Python dependencies
    python3-cairo \
    python-cairo \
    pipx \
    # System utilities
    polkit-qt6-1 \
    lsd \
    neofetch \
    # Handle NVIDIA detection automatically during first boot
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: HYPRLAND APPS & ENVIRONMENT
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Core apps
    pipewire \
    wireplumber \
    brightnessctl \
    qt6-qtwayland \
    dunst \
    rofi-wayland \
    swayidle \
    waybar \
    wlogout \
    grim \
    slurp \
    # System integration
    polkit-kde \
    xdg-desktop-portal-gtk \
    # Graphics and media
    ImageMagick \
    pavucontrol \
    # QT theming
    qt6-qtbase-devel \
    ffmpegthumbs \
    qt5-qtimageformats \
    qt6-qtbase \
    kvantum \
    qt5ct \
    qt6ct \
    # File manager and utilities
    parallel \
    dolphin \
    kde-cli-tools \
    sddm \
    fastfetch \
    || true && \
    # Special cases for Hyprland environment
    if command -v pipx &> /dev/null; then \
    pipx install --global hyprshade || true; \
    fi && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: HYPRDOTS CONFIGURATION
# ==========================================
# Clone and set up the hyprdots configuration
RUN mkdir -p /tmp/hyprdots && \
    cd /tmp/hyprdots && \
    # Clone hyprdots configurations
    git clone https://github.com/Senshi111/hyprland-hyprdots-files.git && \
    # Create directory structure for config
    mkdir -p /etc/skel/.config && \
    # Copy the main configuration to skel for new users
    cd hyprland-hyprdots-files/Theme && \
    cp -r * /etc/skel/.config/ && \
    # Set up Scripts directory specifically
    mkdir -p /etc/skel/.config/hypr/scripts && \
    cp -r Scripts/* /etc/skel/.config/hypr/scripts/ && \
    chmod +x /etc/skel/.config/hypr/scripts/*.sh && \
    # Set proper permissions
    chown -R root:root /etc/skel/.config && \
    # Cleanup
    rm -rf /tmp/hyprdots && \
    ostree container commit

# ==========================================
# SECTION 6: ADDITIONAL CONFIG & BOOT SETUP
# ==========================================
# Configure SDDM, autostart, and environment variables
RUN mkdir -p /etc/skel/.config/hypr && \
    # Create autostart file
    echo "# Autostart applications" > /etc/skel/.config/hypr/autostart.sh && \
    echo "#!/bin/bash" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Start waybar" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "waybar &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Start notification daemon" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "dunst &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Start network manager applet" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "nm-applet --indicator &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Start wallpaper daemon" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "swww init &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Clipboard manager" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "wl-clipboard-history -t &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "clipman restore &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Authentication agent" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "/usr/libexec/polkit-kde-authentication-agent-1 &" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    # Make autostart executable
    chmod +x /etc/skel/.config/hypr/autostart.sh && \
    # Add environment variables to ensure proper Wayland integration
    mkdir -p /etc/environment.d && \
    echo "# Hyprland environment variables" > /etc/environment.d/90-hyprland.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/90-hyprland.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/90-hyprland.conf && \
    echo "XDG_CURRENT_DESKTOP=Hyprland" >> /etc/environment.d/90-hyprland.conf && \
    echo "XDG_SESSION_DESKTOP=Hyprland" >> /etc/environment.d/90-hyprland.conf && \
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment.d/90-hyprland.conf && \
    echo "QT_QPA_PLATFORM=wayland" >> /etc/environment.d/90-hyprland.conf && \
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> /etc/environment.d/90-hyprland.conf && \
    echo "QT_AUTO_SCREEN_SCALE_FACTOR=1" >> /etc/environment.d/90-hyprland.conf && \
    echo "SDL_VIDEODRIVER=wayland" >> /etc/environment.d/90-hyprland.conf && \
    echo "CLUTTER_BACKEND=wayland" >> /etc/environment.d/90-hyprland.conf && \
    echo "_JAVA_AWT_WM_NONREPARENTING=1" >> /etc/environment.d/90-hyprland.conf && \
    # Setup SDDM
    mkdir -p /etc/sddm.conf.d && \
    echo "[General]" > /etc/sddm.conf.d/10-wayland.conf && \
    echo "DisplayServer=wayland" >> /etc/sddm.conf.d/10-wayland.conf && \
    echo "GreeterEnvironment=QT_QPA_PLATFORM=wayland" >> /etc/sddm.conf.d/10-wayland.conf && \
    # Enable SDDM
    systemctl enable sddm.service || true && \
    # Create Hyprland session file
    mkdir -p /usr/share/wayland-sessions && \
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Name=Hyprland" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Comment=An efficient dynamic tiling Wayland compositor" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Exec=Hyprland" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "DesktopNames=Hyprland" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "X-KDE-PluginInfo-Version=1.0" >> /usr/share/wayland-sessions/hyprland.desktop && \
    # Ensure files are accessible
    chmod 755 /usr/share/wayland-sessions/hyprland.desktop && \
    # Final cleanup
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit

# ==========================================
# SECTION 7: FIRST-BOOT SETUP SCRIPT
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "Description=Configure Hyprdots on First Boot" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "After=network.target" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "ExecStart=/usr/bin/hyprdots-firstboot.sh" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/hyprdots-firstboot.service && \
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/hyprdots-firstboot.sh && \
    echo "" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "fi" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "# Create directories for user themes" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-2.0" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-3.0" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-4.0" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/hyprdots-firstboot.sh && \
    echo "systemctl disable hyprdots-firstboot.service" >> /usr/bin/hyprdots-firstboot.sh && \
    chmod +x /usr/bin/hyprdots-firstboot.sh && \
    systemctl enable hyprdots-firstboot.service && \
    ostree container commit

# Copy override files and configure the system
COPY override /

# Final OS branding
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Update system branding more thoroughly from Kinoite to Orb OS
    sed -i 's/Kinoite/Orb OS/g' /etc/os-release && \
    sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="Orb OS Hyprland Hyprdots"/' /etc/os-release && \
    sed -i 's/NAME=.*/NAME="Orb OS"/' /etc/os-release && \
    sed -i 's/ID=.*/ID=orb-os/' /etc/os-release && \
    # Add custom variant information
    echo "VARIANT_ID=hyprland-hyprdots" >> /etc/os-release && \
    echo "VARIANT=Hyprland-Hyprdots" >> /etc/os-release && \
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS Hyprland Hyprdots - $(date +%Y%m%d)" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS Hyprland Hyprdots (\l)" > /etc/issue && \
    echo "Orb OS Hyprland Hyprdots" > /etc/issue.net && \
    echo "Welcome to Orb OS Hyprland Hyprdots!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release
