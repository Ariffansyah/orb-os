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
    firefox \
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
    # Add NodeJS repository
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    # Add PostgreSQL repository
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-$(rpm -E %fedora)-x86_64/pgdg-fedora-repo-latest.noarch.rpm && \
    # Add RPM Fusion repositories
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 3: HYPRLAND & DEPENDENCIES INSTALLATION
# ==========================================
# Install Hyprland and dependencies
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
    gtk3-devel \
    xdg-utils \
    swappy \
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
    fastfetch \
    tmux \
    # Text editors
    neovim \
    # Terminal
    ghostty \
    # Browser (using standard Chromium instead of ungoogled)
    chromium \
    # YoRHa theme dependencies
    eww \
    jq \
    socat \
    unzip \
    rofi-wayland \
    papirus-icon-theme \
    inter-fonts \
    jetbrains-mono-fonts \
    terminus-fonts \
    nerd-fonts \
    fontawesome-fonts \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: PROGRAMMING LANGUAGES & TOOLS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Development tools and build essentials
    gcc \
    gcc-c++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkgconf \
    git \
    vim \
    # NodeJS
    nodejs \
    npm \
    # Golang
    golang \
    # Java
    java-17-openjdk \
    java-17-openjdk-devel \
    maven \
    # Python
    python3 \
    python3-pip \
    python3-devel \
    python3-virtualenv \
    # C/C++
    clang \
    clang-tools-extra \
    gdb \
    # PostgreSQL CLI tools
    postgresql15-client \
    pgcli \
    # Redis server and CLI
    redis \
    # Development libraries
    zlib-devel \
    bzip2-devel \
    openssl-devel \
    readline-devel \
    sqlite-devel \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: HYPRLAND APPS & ENVIRONMENT
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
    # Additional YoRHa theme dependencies
    kitty \
    mpd \
    mpc \
    ncmpcpp \
    btop \
    || true && \
    # Special cases for Hyprland environment
    if command -v pipx &> /dev/null; then \
    pipx install --global hyprshade || true; \
    fi && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: YORHA CONFIGURATION
# ==========================================
# Clone and set up the YoRHa configuration
RUN mkdir -p /tmp/yorha && \
    cd /tmp/yorha && \
    # Try to clone the repository (with fallback to main branch)
    if ! git clone -b hyprland-yorha https://github.com/flickowoa/dotfiles.git; then \
    echo "Failed to clone hyprland-yorha branch, trying main branch..." && \
    git clone https://github.com/flickowoa/dotfiles.git; \
    fi && \
    # Check if the config directories exist, create them if not
    mkdir -p /etc/skel/.config && \
    # Create base directories if they don't exist in the repo
    mkdir -p dotfiles/.config/hypr dotfiles/.config/eww dotfiles/.config/rofi \
    dotfiles/.config/kitty dotfiles/.config/waybar dotfiles/.config/dunst \
    dotfiles/.config/cava dotfiles/.config/mpd dotfiles/.config/ncmpcpp && \
    # Copy configurations to skeleton
    cp -r dotfiles/.config/hypr /etc/skel/.config/ && \
    cp -r dotfiles/.config/eww /etc/skel/.config/ && \
    cp -r dotfiles/.config/rofi /etc/skel/.config/ && \
    cp -r dotfiles/.config/kitty /etc/skel/.config/ && \
    cp -r dotfiles/.config/waybar /etc/skel/.config/ && \
    cp -r dotfiles/.config/dunst /etc/skel/.config/ && \
    cp -r dotfiles/.config/cava /etc/skel/.config/ && \
    cp -r dotfiles/.config/mpd /etc/skel/.config/ && \
    cp -r dotfiles/.config/ncmpcpp /etc/skel/.config/ && \
    # Create basic Hyprland configuration if it's empty
    if [ ! -f "/etc/skel/.config/hypr/hyprland.conf" ]; then \
    echo "# Basic Hyprland Configuration" > /etc/skel/.config/hypr/hyprland.conf && \
    echo "# Generated by Orb OS" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "monitor=,preferred,auto,auto" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "exec-once = ghostty" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "exec-once = waybar" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "exec-once = dunst" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "input {" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    kb_layout = us" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    follow_mouse = 1" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "}" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "general {" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    gaps_in = 5" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    gaps_out = 10" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    border_size = 2" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    col.inactive_border = rgba(595959aa)" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "}" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "decoration {" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    rounding = 10" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "}" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "animations {" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "    enabled = yes" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "}" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "# Key bindings" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, RETURN, exec, ghostty" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, Q, killactive" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, M, exit" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, V, togglefloating" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, F, fullscreen" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, R, exec, rofi -show drun" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "# Move focus with SUPER + arrow keys" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, left, movefocus, l" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, right, movefocus, r" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, up, movefocus, u" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, down, movefocus, d" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "# Switch workspaces with SUPER + [0-9]" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 1, workspace, 1" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 2, workspace, 2" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 3, workspace, 3" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 4, workspace, 4" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 5, workspace, 5" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 6, workspace, 6" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 7, workspace, 7" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 8, workspace, 8" >> /etc/skel/.config/hypr/hyprland.conf && \
    echo "bind = SUPER, 9, workspace, 9" >> /etc/skel/.config/hypr/hyprland.conf; \
    fi && \
    # Create ghostty config directory
    mkdir -p /etc/skel/.config/ghostty && \
    # Create basic ghostty config
    echo "# Ghostty Terminal Configuration" > /etc/skel/.config/ghostty/config && \
    echo "theme = catppuccin-mocha" >> /etc/skel/.config/ghostty/config && \
    echo "font-family = JetBrainsMono Nerd Font" >> /etc/skel/.config/ghostty/config && \
    echo "font-size = 12" >> /etc/skel/.config/ghostty/config && \
    echo "cursor-style = beam" >> /etc/skel/.config/ghostty/config && \
    echo "background-opacity = 0.95" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-x = 10" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-y = 10" >> /etc/skel/.config/ghostty/config && \
    # Create Neovim config directory
    mkdir -p /etc/skel/.config/nvim && \
    # Create basic Neovim init.lua
    echo "-- Neovim Configuration" > /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.number = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.relativenumber = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.shiftwidth = 2" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.tabstop = 2" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.expandtab = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.cursorline = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.termguicolors = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.mouse = 'a'" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.clipboard = 'unnamedplus'" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.g.mapleader = ' '" >> /etc/skel/.config/nvim/init.lua && \
    # Set up tmux configuration
    echo "# Tmux Configuration" > /etc/skel/.tmux.conf && \
    echo "set -g default-terminal \"screen-256color\"" >> /etc/skel/.tmux.conf && \
    echo "set -g status-style bg=default,fg=white" >> /etc/skel/.tmux.conf && \
    echo "set -g status-left-length 40" >> /etc/skel/.tmux.conf && \
    echo "set -g mouse on" >> /etc/skel/.tmux.conf && \
    echo "set -sg escape-time 0" >> /etc/skel/.tmux.conf && \
    echo "set -g base-index 1" >> /etc/skel/.tmux.conf && \
    echo "setw -g pane-base-index 1" >> /etc/skel/.tmux.conf && \
    echo "bind r source-file ~/.tmux.conf \; display \"Config Reloaded\"" >> /etc/skel/.tmux.conf && \
    echo "bind | split-window -h" >> /etc/skel/.tmux.conf && \
    echo "bind - split-window -v" >> /etc/skel/.tmux.conf && \
    echo "bind -r C-h select-window -t :-" >> /etc/skel/.tmux.conf && \
    echo "bind -r C-l select-window -t :+" >> /etc/skel/.tmux.conf && \
    # Copy fonts if present
    if [ -d "dotfiles/.local/share/fonts" ]; then \
    mkdir -p /etc/skel/.local/share/fonts && \
    cp -r dotfiles/.local/share/fonts/* /etc/skel/.local/share/fonts/ && \
    fc-cache -f; \
    fi && \
    # Copy wallpapers if present
    if [ -d "dotfiles/wallpapers" ]; then \
    mkdir -p /etc/skel/wallpapers && \
    cp -r dotfiles/wallpapers/* /etc/skel/wallpapers/; \
    fi && \
    # Set Chromium as default browser
    echo "[Default Applications]" > /etc/skel/.config/mimeapps.list && \
    echo "text/html=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/http=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/https=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/ftp=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/chrome=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/x-extension-htm=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/x-extension-html=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/x-extension-shtml=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/xhtml+xml=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/x-extension-xhtml=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "application/x-extension-xht=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    # Cleanup
    rm -rf /tmp/yorha && \
    ostree container commit
# ==========================================
# SECTION 7: ADDITIONAL CONFIG & BOOT SETUP
# ==========================================
# Configure autostart and environment variables
RUN mkdir -p /etc/skel/.config/hypr/autostart && \
    # Create autostart file
    echo "#!/bin/bash" > /etc/skel/.config/hypr/autostart.sh && \
    echo "" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "# Start eww daemon" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "eww daemon &" >> /etc/skel/.config/hypr/autostart.sh && \
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
    echo "# MPD daemon start (for music in eww widget)" >> /etc/skel/.config/hypr/autostart.sh && \
    echo "[ ! -s ~/.config/mpd/pid ] && mpd" >> /etc/skel/.config/hypr/autostart.sh && \
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
    echo "GOPATH=/usr/local/go" >> /etc/environment.d/90-hyprland.conf && \
    echo "PATH=$PATH:/usr/local/go/bin" >> /etc/environment.d/90-hyprland.conf && \
    # Setup SDDM
    mkdir -p /etc/sddm.conf.d && \
    echo "[General]" > /etc/sddm.conf.d/10-wayland.conf && \
    echo "DisplayServer=wayland" >> /etc/sddm.conf.d/10-wayland.conf && \
    echo "GreeterEnvironment=QT_QPA_PLATFORM=wayland" >> /etc/sddm.conf.d/10-wayland.conf && \
    # Enable services
    systemctl enable sddm.service || true && \
    systemctl enable redis.service || true && \
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
    # Remove Plasma sessions
    rm -f /usr/share/wayland-sessions/plasmawayland.desktop && \
    rm -f /usr/share/xsessions/plasma.desktop && \
    # Final cleanup
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit

# ==========================================
# SECTION 8: KDE-LIKE SDDM THEME SETUP
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install SDDM KDE theme dependencies
    rpm-ostree install \
    sddm-kcm \
    sddm-breeze \
    breeze-gtk \
    breeze-icon-theme \
    || true && \
    # Configure SDDM to use Breeze theme
    mkdir -p /etc/sddm.conf.d && \
    echo "[Theme]" > /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "Current=breeze" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "CursorTheme=breeze_cursors" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "Font=Noto Sans" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "[Users]" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "MaximumUid=60000" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "MinimumUid=1000" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "[X11]" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "EnableHiDPI=true" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "[Wayland]" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "EnableHiDPI=true" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    echo "" >> /etc/sddm.conf.d/10-kde-theme.conf && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 9: FIRST-BOOT SETUP SCRIPT
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "Description=Configure YoRHa Theme on First Boot" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "After=network.target" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "ExecStart=/usr/bin/yorha-firstboot.sh" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/yorha-firstboot.service && \
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Configure SDDM to look like KDE" >> /usr/bin/yorha-firstboot.sh && \
    echo "if [ -d \"/usr/share/sddm/themes/breeze\" ]; then" >> /usr/bin/yorha-firstboot.sh && \
    echo "    echo \"Configuring SDDM with KDE Breeze theme...\"" >> /usr/bin/yorha-firstboot.sh && \
    echo "    # Make sure SDDM uses the breeze theme" >> /usr/bin/yorha-firstboot.sh && \
    echo "    mkdir -p /etc/sddm.conf.d" >> /usr/bin/yorha-firstboot.sh && \
    echo "    echo \"[Theme]\" > /etc/sddm.conf.d/10-kde-theme.conf" >> /usr/bin/yorha-firstboot.sh && \
    echo "    echo \"Current=breeze\" >> /etc/sddm.conf.d/10-kde-theme.conf" >> /usr/bin/yorha-firstboot.sh && \
    echo "    echo \"CursorTheme=breeze_cursors\" >> /etc/sddm.conf.d/10-kde-theme.conf" >> /usr/bin/yorha-firstboot.sh && \
    echo "    # Copy KDE Plasma wallpaper for SDDM background if available" >> /usr/bin/yorha-firstboot.sh && \
    echo "    if [ -d \"/usr/share/wallpapers/Next\" ]; then" >> /usr/bin/yorha-firstboot.sh && \
    echo "        cp -r /usr/share/wallpapers/Next /usr/share/sddm/themes/breeze/" >> /usr/bin/yorha-firstboot.sh && \
    echo "        echo \"Background=/usr/share/sddm/themes/breeze/Next/contents/images/1920x1080.png\" >> /etc/sddm.conf.d/10-kde-theme.conf" >> /usr/bin/yorha-firstboot.sh && \
    echo "    fi" >> /usr/bin/yorha-firstboot.sh && \
    echo "fi" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Setup programming language environments" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Set up Node.js global packages" >> /usr/bin/yorha-firstboot.sh && \
    echo "npm install -g yarn typescript ts-node nodemon" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Set up Python global packages" >> /usr/bin/yorha-firstboot.sh && \
    echo "pip3 install --upgrade pip" >> /usr/bin/yorha-firstboot.sh && \
    echo "pip3 install virtualenv black flake8 mypy pytest jupyter" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Set up Go environment" >> /usr/bin/yorha-firstboot.sh && \
    echo "mkdir -p /usr/local/go" >> /usr/bin/yorha-firstboot.sh && \
    echo "echo 'export GOPATH=/usr/local/go' >> /etc/profile.d/go.sh" >> /usr/bin/yorha-firstboot.sh && \
    echo "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh" >> /usr/bin/yorha-firstboot.sh && \
    echo "chmod +x /etc/profile.d/go.sh" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Set up Neovim plugins" >> /usr/bin/yorha-firstboot.sh && \
    echo "mkdir -p /etc/skel/.local/share/nvim/site/pack/packer/start" >> /usr/bin/yorha-firstboot.sh && \
    echo "git clone --depth 1 https://github.com/wbthomason/packer.nvim /etc/skel/.local/share/nvim/site/pack/packer/start/packer.nvim" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Setup Redis service" >> /usr/bin/yorha-firstboot.sh && \
    echo "if command -v redis-server &> /dev/null; then" >> /usr/bin/yorha-firstboot.sh && \
    echo "    systemctl enable redis" >> /usr/bin/yorha-firstboot.sh && \
    echo "fi" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/yorha-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/yorha-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/yorha-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/yorha-firstboot.sh && \
    echo "fi" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Set up GTK theme to match YoRHa style" >> /usr/bin/yorha-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-2.0" >> /usr/bin/yorha-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-3.0" >> /usr/bin/yorha-firstboot.sh && \
    echo "mkdir -p /etc/xdg/gtk-4.0" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Ensure EWW service is running for logged in users" >> /usr/bin/yorha-firstboot.sh && \
    echo "echo 'systemctl --user enable --now eww.service' > /etc/skel/.config/autostart/eww.desktop" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Configure default browser" >> /usr/bin/yorha-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.bashrc" >> /usr/bin/yorha-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.zshrc" >> /usr/bin/yorha-firstboot.sh && \
    echo "" >> /usr/bin/yorha-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/yorha-firstboot.sh && \
    echo "systemctl disable yorha-firstboot.service" >> /usr/bin/yorha-firstboot.sh && \
    chmod +x /usr/bin/yorha-firstboot.sh && \
    systemctl enable yorha-firstboot.service && \
    ostree container commit

# ==========================================
# SECTION 10: COMPLETE SDDM CONFIGURATION
# ==========================================
# Create complete SDDM configuration with KDE look and feel
RUN echo "[Autologin]" > /etc/sddm.conf && \
    echo "# Autologin is disabled by default" >> /etc/sddm.conf && \
    echo "Relogin=false" >> /etc/sddm.conf && \
    echo "Session=" >> /etc/sddm.conf && \
    echo "User=" >> /etc/sddm.conf && \
    echo "" >> /etc/sddm.conf && \
    echo "[General]" >> /etc/sddm.conf && \
    echo "DisplayServer=wayland" >> /etc/sddm.conf && \
    echo "GreeterEnvironment=QT_QPA_PLATFORM=wayland" >> /etc/sddm.conf && \
    echo "HaltCommand=/usr/bin/systemctl poweroff" >> /etc/sddm.conf && \
    echo "Numlock=on" >> /etc/sddm.conf && \
    echo "RebootCommand=/usr/bin/systemctl reboot" >> /etc/sddm.conf && \
    echo "" >> /etc/sddm.conf && \
    echo "[Theme]" >> /etc/sddm.conf && \
    echo "Current=breeze" >> /etc/sddm.conf && \
    echo "CursorTheme=breeze_cursors" >> /etc/sddm.conf && \
    echo "Font=Noto Sans,10,-1,5,50,0,0,0,0,0" >> /etc/sddm.conf && \
    echo "" >> /etc/sddm.conf && \
    echo "[Users]" >> /etc/sddm.conf && \
    echo "DefaultPath=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/sddm.conf && \
    echo "HideShells=" >> /etc/sddm.conf && \
    echo "HideUsers=" >> /etc/sddm.conf && \
    echo "MaximumUid=60000" >> /etc/sddm.conf && \
    echo "MinimumUid=1000" >> /etc/sddm.conf && \
    echo "RememberLastSession=true" >> /etc/sddm.conf && \
    echo "RememberLastUser=true" >> /etc/sddm.conf && \
    echo "" >> /etc/sddm.conf && \
    echo "[Wayland]" >> /etc/sddm.conf && \
    echo "EnableHiDPI=true" >> /etc/sddm.conf && \
    echo "SessionCommand=/usr/share/sddm/scripts/wayland-session" >> /etc/sddm.conf && \
    echo "SessionDir=/usr/share/wayland-sessions" >> /etc/sddm.conf && \
    echo "" >> /etc/sddm.conf && \
    echo "[X11]" >> /etc/sddm.conf && \
    echo "EnableHiDPI=true" >> /etc/sddm.conf && \
    echo "ServerPath=/usr/bin/X" >> /etc/sddm.conf && \
    echo "SessionCommand=/usr/share/sddm/scripts/Xsession" >> /etc/sddm.conf && \
    echo "SessionDir=/usr/share/xsessions" >> /etc/sddm.conf && \
    echo "XauthPath=/usr/bin/xauth" >> /etc/sddm.conf && \
    echo "XephyrPath=/usr/bin/Xephyr" >> /etc/sddm.conf

# Copy override files and configure the system
COPY override /

# Final OS branding
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Update system branding more thoroughly from Kinoite to Orb OS
    sed -i 's/Kinoite/Orb OS/g' /etc/os-release && \
    sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="Orb OS Hyprland YoRHa"/' /etc/os-release && \
    sed -i 's/NAME=.*/NAME="Orb OS"/' /etc/os-release && \
    sed -i 's/ID=.*/ID=orb-os/' /etc/os-release && \
    # Add custom variant information
    echo "VARIANT_ID=hyprland-yorha" >> /etc/os-release && \
    echo "VARIANT=Hyprland-YoRHa" >> /etc/os-release && \
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS Hyprland YoRHa - 2025-05-09 06:53:07" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS Hyprland YoRHa (\l)" > /etc/issue && \
    echo "Orb OS Hyprland YoRHa" > /etc/issue.net && \
    echo "Welcome to Orb OS Hyprland with YoRHa theme!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release
