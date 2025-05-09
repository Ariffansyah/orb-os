FROM ghcr.io/ublue-os/base-main:42

# Define build arguments
ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-cosmic}"
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
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo || true && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo || true && \
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
# SECTION 3: DESKTOP ENVIRONMENT INSTALLATION
# ==========================================
# Install GNOME desktop environment
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install essential display packages
    rpm-ostree install \
    gdm \
    switcheroo-control \
    libglvnd \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install GNOME core
    rpm-ostree install \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-tweaks \
    gnome-shell-extension-appindicator \
    gnome-terminal \
    gnome-backgrounds \
    gnome-themes-extra \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install core desktop environment requirements
    rpm-ostree install \
    wl-clipboard \
    gtk3-devel \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    polkit-gnome \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: ADDITIONAL SOFTWARE
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Fonts and themes
    rpm-ostree install \
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    arc-theme \
    papirus-icon-theme \
    breeze-cursor-theme \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Audio and sensors
    rpm-ostree install \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber \
    pamixer \
    alsa-ucm \
    alsa-firmware \
    alsa-sof-firmware \
    lm_sensors \
    cava \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Bluetooth and Network
    rpm-ostree install \
    bluez \
    bluez-tools \
    blueman \
    NetworkManager-wifi \
    network-manager-applet \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Python dependencies and system utilities
    rpm-ostree install \
    python3-cairo \
    python-cairo \
    pipx \
    polkit-qt6-1 \
    lsd \
    fastfetch \
    tmux \
    neofetch \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Text editors
    rpm-ostree install \
    neovim \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Terminal and Browser
    rpm-ostree install \
    ghostty \
    alacritty \
    chromium \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Fonts
    rpm-ostree install \
    inter-fonts \
    jetbrains-mono-fonts \
    terminus-fonts \
    nerd-fonts \
    fontawesome-fonts \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: PROGRAMMING LANGUAGES & TOOLS
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
# SECTION 6: DESKTOP ENVIRONMENT SETUP
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Core apps for Wayland
    brightnessctl \
    qt6-qtwayland \
    rofi-wayland \
    swayidle \
    grim \
    slurp \
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
    nautilus \
    # Additional utilities
    btop \
    || true && \
    # Enable GDM
    systemctl enable gdm.service && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 7: DESKTOP CONFIGURATION
# ==========================================
# Set up the desktop configuration
RUN mkdir -p /etc/skel/.config && \
    # Create Ghostty config directory
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
    # Create Alacritty config directory
    mkdir -p /etc/skel/.config/alacritty && \
    # Create basic Alacritty config
    echo "# Alacritty Terminal Configuration" > /etc/skel/.config/alacritty/alacritty.yml && \
    echo "font:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  normal:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    family: JetBrainsMono Nerd Font" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  size: 12" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "window:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  opacity: 0.95" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  padding:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    x: 10" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    y: 10" >> /etc/skel/.config/alacritty/alacritty.yml && \
    # Create Fastfetch config directory and file
    mkdir -p /etc/skel/.config/fastfetch && \
    echo "# Fastfetch Configuration" > /etc/skel/.config/fastfetch/config.jsonc && \
    echo "{" >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    "logo": {' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "type": "small",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "padding": {' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '            "left": 2,' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '            "right": 2' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        }' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    },' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    "display": {' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "separator": "  ",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "keyWidth": 15' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    },' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    "modules": [' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "title",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "os",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "kernel",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "uptime",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "packages",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "shell",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "de",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "wm",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "terminal",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "cpu",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "memory",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "disk"' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    ]' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '}' >> /etc/skel/.config/fastfetch/config.jsonc && \
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
    # Create user bash profile
    echo "# .bash_profile" > /etc/skel/.bash_profile && \
    echo "" >> /etc/skel/.bash_profile && \
    echo "# Get the aliases and functions" >> /etc/skel/.bash_profile && \
    echo "if [ -f ~/.bashrc ]; then" >> /etc/skel/.bash_profile && \
    echo "    . ~/.bashrc" >> /etc/skel/.bash_profile && \
    echo "fi" >> /etc/skel/.bash_profile && \
    echo "" >> /etc/skel/.bash_profile && \
    echo "# User specific environment and startup programs" >> /etc/skel/.bash_profile && \
    echo "PATH=\$PATH:\$HOME/.local/bin" >> /etc/skel/.bash_profile && \
    echo "export PATH" >> /etc/skel/.bash_profile && \
    # Create better bashrc
    echo "# .bashrc" > /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# Source global definitions" >> /etc/skel/.bashrc && \
    echo "if [ -f /etc/bashrc ]; then" >> /etc/skel/.bashrc && \
    echo "    . /etc/bashrc" >> /etc/skel/.bashrc && \
    echo "fi" >> /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# User specific aliases and functions" >> /etc/skel/.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/skel/.bashrc && \
    echo "alias ll='ls -la'" >> /etc/skel/.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# Set prompt" >> /etc/skel/.bashrc && \
    echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# Run fastfetch if it exists" >> /etc/skel/.bashrc && \
    echo "if command -v fastfetch &> /dev/null; then" >> /etc/skel/.bashrc && \
    echo "    fastfetch" >> /etc/skel/.bashrc && \
    echo "fi" >> /etc/skel/.bashrc && \
    # Set Chromium as default browser
    mkdir -p /etc/skel/.config && \
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
    echo "application/x-extension-xht=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list

# ==========================================
# SECTION 8: ADDITIONAL CONFIG & BOOT SETUP
# ==========================================
# Configure autostart and environment variables
RUN mkdir -p /etc/skel/.config/autostart && \
    # Create autostart file for NetworkManager applet
    echo "[Desktop Entry]" > /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Type=Application" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Name=Network Manager Applet" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Exec=nm-applet --indicator" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Terminal=false" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "X-GNOME-Autostart-enabled=true" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    # Add environment variables to ensure proper Wayland integration
    mkdir -p /etc/environment.d && \
    echo "# Desktop environment variables" > /etc/environment.d/90-desktop-env.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_CURRENT_DESKTOP=GNOME" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_SESSION_DESKTOP=gnome" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_QPA_PLATFORM=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_AUTO_SCREEN_SCALE_FACTOR=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "SDL_VIDEODRIVER=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "CLUTTER_BACKEND=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "_JAVA_AWT_WM_NONREPARENTING=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "GOPATH=/usr/local/go" >> /etc/environment.d/90-desktop-env.conf && \
    echo "PATH=$PATH:/usr/local/go/bin" >> /etc/environment.d/90-desktop-env.conf && \
    # Create session files
    mkdir -p /usr/share/wayland-sessions && \
    mkdir -p /usr/share/xsessions && \
    # Create GNOME Wayland session file
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/gnome.desktop && \
    echo "Name=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Exec=gnome-session" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    # Create X11 fallback session
    echo "[Desktop Entry]" > /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Name=GNOME on Xorg" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Exec=gnome-session" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Type=Application" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    # Fix permissions on session files
    chmod 644 /usr/share/wayland-sessions/*.desktop && \
    chmod 644 /usr/share/xsessions/*.desktop && \
    # Ensure graphical target is set as default
    systemctl set-default graphical.target && \
    # Create profile.d script to fix "command not found" error
    echo '#!/bin/bash' > /etc/profile.d/welcome.sh && \
    echo 'if [ -f /etc/motd ]; then' >> /etc/profile.d/welcome.sh && \
    echo '    cat /etc/motd' >> /etc/profile.d/welcome.sh && \
    echo 'fi' >> /etc/profile.d/welcome.sh && \
    chmod +x /etc/profile.d/welcome.sh

# ==========================================
# SECTION 9: GNOME THEME SETUP
# ==========================================
RUN mkdir -p /etc/dconf/db/local.d && \
    # Create theme settings
    echo "[org/gnome/desktop/interface]" > /etc/dconf/db/local.d/01-theme && \
    echo "gtk-theme='Arc-Dark'" >> /etc/dconf/db/local.d/01-theme && \
    echo "icon-theme='Papirus-Dark'" >> /etc/dconf/db/local.d/01-theme && \
    echo "cursor-theme='Breeze_Snow'" >> /etc/dconf/db/local.d/01-theme && \
    echo "font-name='Inter 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "document-font-name='Inter 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "monospace-font-name='JetBrainsMono Nerd Font 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "color-scheme='prefer-dark'" >> /etc/dconf/db/local.d/01-theme && \
    echo "" >> /etc/dconf/db/local.d/01-theme && \
    echo "[org/gnome/shell]" >> /etc/dconf/db/local.d/01-theme && \
    echo "enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com']" >> /etc/dconf/db/local.d/01-theme && \
    echo "" >> /etc/dconf/db/local.d/01-theme && \
    echo "[org/gnome/desktop/peripherals/touchpad]" >> /etc/dconf/db/local.d/01-theme && \
    echo "natural-scroll=false" >> /etc/dconf/db/local.d/01-theme && \
    echo "tap-to-click=true" >> /etc/dconf/db/local.d/01-theme && \
    echo "two-finger-scrolling-enabled=true" >> /etc/dconf/db/local.d/01-theme && \
    # Create keyboard shortcut settings
    echo "[org/gnome/settings-daemon/plugins/media-keys]" > /etc/dconf/db/local.d/02-keybindings && \
    echo "custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" >> /etc/dconf/db/local.d/02-keybindings && \
    echo "" >> /etc/dconf/db/local.d/02-keybindings && \
    echo "[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]" >> /etc/dconf/db/local.d/02-keybindings && \
    echo "binding='<Super>t'" >> /etc/dconf/db/local.d/02-keybindings && \
    echo "command='alacritty'" >> /etc/dconf/db/local.d/02-keybindings && \
    echo "name='Terminal'" >> /etc/dconf/db/local.d/02-keybindings && \
    # Desktop layout settings
    echo "[org/gnome/shell]" > /etc/dconf/db/local.d/03-desktop && \
    echo "favorite-apps=['chromium-browser.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop']" >> /etc/dconf/db/local.d/03-desktop && \
    echo "" >> /etc/dconf/db/local.d/03-desktop && \
    echo "[org/gnome/desktop/wm/preferences]" >> /etc/dconf/db/local.d/03-desktop && \
    echo "button-layout=':minimize,maximize,close'" >> /etc/dconf/db/local.d/03-desktop && \
    echo "" >> /etc/dconf/db/local.d/03-desktop && \
    echo "[org/gnome/mutter]" >> /etc/dconf/db/local.d/03-desktop && \
    echo "dynamic-workspaces=true" >> /etc/dconf/db/local.d/03-desktop && \
    echo "workspaces-only-on-primary=true" >> /etc/dconf/db/local.d/03-desktop && \
    mkdir -p /etc/dconf/profile && \
    echo "user-db:user" > /etc/dconf/profile/user && \
    echo "system-db:local" >> /etc/dconf/profile/user && \
    # Update dconf database
    dconf update 2>/dev/null || true

# ==========================================
# SECTION 10: FIRST-BOOT SETUP SCRIPT
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Description=Configure Orb OS COSMIC-like on First Boot" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "After=network.target" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "ExecStart=/usr/bin/orb-firstboot.sh" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/orb-firstboot.service && \
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Setup programming language environments" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set up Node.js global packages" >> /usr/bin/orb-firstboot.sh && \
    echo "npm install -g yarn typescript ts-node nodemon" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set up Python global packages" >> /usr/bin/orb-firstboot.sh && \
    echo "pip3 install --upgrade pip" >> /usr/bin/orb-firstboot.sh && \
    echo "pip3 install virtualenv black flake8 mypy pytest jupyter" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set up Go environment" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /usr/local/go" >> /usr/bin/orb-firstboot.sh && \
    echo "echo 'export GOPATH=/usr/local/go' >> /etc/profile.d/go.sh" >> /usr/bin/orb-firstboot.sh && \
    echo "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh" >> /usr/bin/orb-firstboot.sh && \
    echo "chmod +x /etc/profile.d/go.sh" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set up Neovim plugins" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/.local/share/nvim/site/pack/packer/start" >> /usr/bin/orb-firstboot.sh && \
    echo "git clone --depth 1 https://github.com/wbthomason/packer.nvim /etc/skel/.local/share/nvim/site/pack/packer/start/packer.nvim" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Setup Redis service" >> /usr/bin/orb-firstboot.sh && \
    echo "if command -v redis-server &> /dev/null; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    systemctl enable redis" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Ensure GDM is enabled" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl enable gdm.service" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl set-default graphical.target" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Update dconf database" >> /usr/bin/orb-firstboot.sh && \
    echo "dconf update" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/orb-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/orb-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Configure default browser" >> /usr/bin/orb-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.bashrc" >> /usr/bin/orb-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.zshrc" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl disable orb-firstboot.service" >> /usr/bin/orb-firstboot.sh && \
    chmod +x /usr/bin/orb-firstboot.sh && \
    systemctl enable orb-firstboot.service

# Copy override files and configure the system
COPY override /

# Final OS branding
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Update system branding more thoroughly from Kinoite to Orb OS
    sed -i 's/Kinoite/Orb OS/g' /etc/os-release && \
    sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="Orb OS COSMIC"/' /etc/os-release && \
    sed -i 's/NAME=.*/NAME="Orb OS"/' /etc/os-release && \
    sed -i 's/ID=.*/ID=orb-os/' /etc/os-release && \
    # Add custom variant information
    echo "VARIANT_ID=cosmic" >> /etc/os-release && \
    echo "VARIANT=COSMIC" >> /etc/os-release && \
    echo "CURRENT_USER=Ariffansyah" >> /etc/os-release && \
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC - 2025-05-09 12:32:48" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC-like desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release
