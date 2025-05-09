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
    libdrm \
    libdecor \
    atk \
    at-spi2-atk \
    || true && \
    rpm-ostree override remove \
    glibc32 \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 2: REPOSITORY SETUP
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/_copr_solopasha-hyprland.repo \
    https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-"${FEDORA_MAJOR_VERSION}"/solopasha-hyprland-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 3: HYPRLAND & DEPENDENCIES INSTALLATION
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    hyprland \
    cliphist \
    xdg-desktop-portal-hyprland \
    swww \
    wl-clipboard \
    google-noto-emoji-fonts \
    pamixer \
    alsa-ucm \
    alsa-firmware \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: HYPRLAND APPS & ENVIRONMENT
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    pipewire \
    wireplumber \
    brightnessctl \
    qt6-qtwayland \
    dunst \
    rofi-wayland \
    swayidle \
    waybar \
    grim \
    slurp \
    pavucontrol \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: HYPRDOTS CONFIGURATION
# ==========================================
RUN mkdir -p /tmp/hyprdots && \
    cd /tmp/hyprdots && \
    git clone https://github.com/Ariffansyah/fedora-hyprland-hyprdots.git && \
    cd fedora-hyprland-hyprdots/build-hyprland-and-apps && \
    ./install_all.sh && \
    mkdir -p /etc/skel/.config/hypr && \
    cp -r ~/.config/hypr/* /etc/skel/.config/hypr/ && \
    chmod -R 755 /etc/skel/.config/hypr && \
    rm -rf /tmp/hyprdots && \
    ostree container commit

# ==========================================
# SECTION 6: ADDITIONAL CONFIG & BOOT SETUP
# ==========================================
RUN mkdir -p /etc/skel/.config/hypr && \
    echo "# Autostart applications" > /etc/skel/.config/hypr/autostart.sh && \
    echo "#!/bin/bash" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "bash /usr/bin/hyprdots-firstlogin.sh" >> /etc/skel/.config/hypr/autostart.sh && \
    chmod +x /etc/skel/.config/hypr/autostart.sh && \
    mkdir -p /etc/environment.d && \
    echo "MOZ_ENABLE_WAYLAND=1" > /etc/environment.d/90-hyprland.conf && \
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
    ostree container commit

# ==========================================
# SECTION 7: FIRST-LOGIN CONFIGURATION SCRIPT
# ==========================================
RUN mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/hyprdots-firstlogin.sh && \
    echo "if [ ! -d ~/.config/hypr ]; then" >> /usr/bin/hyprdots-firstlogin.sh && \
    echo "    cp -r /etc/skel/.config/hypr ~/.config/hypr" >> /usr/bin/hyprdots-firstlogin.sh && \
    echo "    chmod -R 755 ~/.config/hypr" >> /usr/bin/hyprdots-firstlogin.sh && \
    echo "fi" >> /usr/bin/hyprdots-firstlogin.sh && \
    chmod +x /usr/bin/hyprdots-firstlogin.sh

# ==========================================
# SECTION 8: FINAL SDDM CONFIGURATION
# ==========================================
RUN mkdir -p /etc/sddm.conf.d && \
    echo "[Theme]" > /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "Current=breeze" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "CursorTheme=breeze_cursors" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "Font=Noto Sans" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    rm -f /usr/share/wayland-sessions/plasmawayland.desktop && \
    rm -f /usr/share/xsessions/plasma.desktop && \
    mkdir -p /usr/share/wayland-sessions && \
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Name=Hyprland" >> /usr/share/wayland-sessions/hyprland.desktop && \
    echo "Exec=Hyprland" >> /usr/share/wayland-sessions/hyprland.desktop && \
    chmod 755 /usr/share/wayland-sessions/hyprland.desktop && \
    ostree container commit

# ==========================================
# SECTION 9: FINAL OS BRANDING
# ==========================================
RUN sed -i 's/Kinoite/Orb OS/g' /etc/os-release && \
    sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="Orb OS Hyprland Hyprdots"/' /etc/os-release && \
    sed -i 's/NAME=.*/NAME="Orb OS"/' /etc/os-release && \
    sed -i 's/ID=.*/ID=orb-os/' /etc/os-release && \
    echo "VARIANT_ID=hyprland-hyprdots" >> /etc/os-release && \
    echo "VARIANT=Hyprland-Hyprdots" >> /etc/os-release && \
    echo "Orb OS Hyprland Hyprdots - $(date +%Y%m%d)" > /etc/orb-os/version && \
    echo "Orb OS Hyprland Hyprdots (\l)" > /etc/issue && \
    echo "Orb OS Hyprland Hyprdots" > /etc/issue.net && \
    echo "Welcome to Orb OS Hyprland Hyprdots!" > /etc/motd && \
    cp /etc/os-release /etc/orb-os-release
