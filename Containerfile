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
    # Create custom cosmic repository
    echo "[system76-cosmic]" > /etc/yum.repos.d/system76-cosmic.repo && \
    echo "name=COSMIC Desktop Environment for Fedora" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "baseurl=https://rpm.system76.com/fedora/\$releasever/system76-cosmic" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "repo_gpgcheck=0" >> /etc/yum.repos.d/system76-cosmic.repo && \
    # Add RPM Fusion repositories
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    # Add NodeJS repository
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 3: DISPLAY SERVER AND LOGIN MANAGER
# ==========================================
# Install display server and login manager first
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install essential display packages
    rpm-ostree install -y \
    gdm \
    wlroots \
    wayland \
    wayland-protocols \
    xorg-x11-server-Xwayland \
    libinput \
    libglvnd \
    egl-wayland \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    mesa-libGL \
    mesa-libEGL \
    mesa-libGLU \
    || true && \
    systemctl enable gdm.service && \
    systemctl set-default graphical.target && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: COSMIC DESKTOP & CORE COMPONENTS
# ==========================================
# Try to install COSMIC packages from system76 repo or available packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # First attempt with system76 repo
    rpm-ostree install \
    cosmic-session \
    cosmic-desktop \
    cosmic-settings \
    cosmic-applets \
    cosmic-panel \
    cosmic-launcher \
    cosmic-workspaces \
    cosmic-bg \
    cosmic-comp \
    cosmic-osd \
    cosmic-notifications \
    cosmic-applibrary \
    || true && \
    # Install GNOME shell as fallback if COSMIC fails
    rpm-ostree install \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-terminal \
    || true && \
    # Install core desktop environment components
    rpm-ostree install \
    wl-clipboard \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    polkit-gnome \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: ADDITIONAL DESKTOP COMPONENTS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Fonts and themes
    rpm-ostree install \
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    arc-theme \
    papirus-icon-theme \
    || true && \
    # Audio and sensors
    rpm-ostree install \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber \
    alsa-ucm \
    alsa-firmware \
    alsa-sof-firmware \
    lm_sensors \
    || true && \
    # Bluetooth and Network
    rpm-ostree install \
    bluez \
    bluez-tools \
    NetworkManager-wifi \
    network-manager-applet \
    || true && \
    # Core applications
    rpm-ostree install \
    chromium \
    alacritty \
    nautilus \
    ghostty \
    neovim \
    || true && \
    # Install ZSH and neofetch
    rpm-ostree install \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    neofetch \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: PROGRAMMING LANGUAGES & TOOLS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install development tools and programming languages
    rpm-ostree install \
    gcc \
    gcc-c++ \
    make \
    cmake \
    git \
    vim \
    nodejs \
    npm \
    golang \
    python3 \
    python3-pip \
    python3-devel \
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
# SECTION 7: ZSH CONFIGURATION
# ==========================================
# Set up ZSH configuration
RUN mkdir -p /etc/skel/.config && \
    # Create ZSH configuration
    echo "# ZSH Configuration" > /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# History settings" >> /etc/skel/.zshrc && \
    echo "HISTFILE=~/.zsh_history" >> /etc/skel/.zshrc && \
    echo "HISTSIZE=10000" >> /etc/skel/.zshrc && \
    echo "SAVEHIST=10000" >> /etc/skel/.zshrc && \
    echo "setopt appendhistory" >> /etc/skel/.zshrc && \
    echo "setopt sharehistory" >> /etc/skel/.zshrc && \
    echo "setopt incappendhistory" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Basic auto/tab completion" >> /etc/skel/.zshrc && \
    echo "autoload -U compinit" >> /etc/skel/.zshrc && \
    echo "compinit" >> /etc/skel/.zshrc && \
    echo "zstyle ':completion:*' menu select" >> /etc/skel/.zshrc && \
    echo "zmodload zsh/complist" >> /etc/skel/.zshrc && \
    echo "_comp_options+=(globdots)" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Enable colors" >> /etc/skel/.zshrc && \
    echo "autoload -U colors && colors" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Load plugins if available" >> /etc/skel/.zshrc && \
    echo "if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then" >> /etc/skel/.zshrc && \
    echo "    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /etc/skel/.zshrc && \
    echo "fi" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then" >> /etc/skel/.zshrc && \
    echo "    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /etc/skel/.zshrc && \
    echo "fi" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Custom prompt" >> /etc/skel/.zshrc && \
    echo "PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Aliases" >> /etc/skel/.zshrc && \
    echo "alias ls='ls --color=auto'" >> /etc/skel/.zshrc && \
    echo "alias ll='ls -la'" >> /etc/skel/.zshrc && \
    echo "alias grep='grep --color=auto'" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Run fastfetch if it exists" >> /etc/skel/.zshrc && \
    echo "if command -v fastfetch &> /dev/null; then" >> /etc/skel/.zshrc && \
    echo "    fastfetch" >> /etc/skel/.zshrc && \
    echo "elif command -v neofetch &> /dev/null; then" >> /etc/skel/.zshrc && \
    echo "    neofetch" >> /etc/skel/.zshrc && \
    echo "fi" >> /etc/skel/.zshrc && \
    # Create .zshenv file
    echo "# ZSH Environment" > /etc/skel/.zshenv && \
    echo "" >> /etc/skel/.zshenv && \
    echo "# Set PATH" >> /etc/skel/.zshenv && \
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> /etc/skel/.zshenv && \
    echo "" >> /etc/skel/.zshenv

# ==========================================
# SECTION 8: USER CONFIGURATION
# ==========================================
# Set up user configuration files
RUN mkdir -p /etc/skel/.config && \
    # Create Ghostty config
    mkdir -p /etc/skel/.config/ghostty && \
    echo "# Ghostty Terminal Configuration" > /etc/skel/.config/ghostty/config && \
    echo "theme = catppuccin-mocha" >> /etc/skel/.config/ghostty/config && \
    echo "font-family = JetBrainsMono Nerd Font" >> /etc/skel/.config/ghostty/config && \
    echo "font-size = 12" >> /etc/skel/.config/ghostty/config && \
    echo "cursor-style = beam" >> /etc/skel/.config/ghostty/config && \
    echo "background-opacity = 0.95" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-x = 10" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-y = 10" >> /etc/skel/.config/ghostty/config && \
    echo "shell = /bin/zsh" >> /etc/skel/.config/ghostty/config && \
    # Create Alacritty config
    mkdir -p /etc/skel/.config/alacritty && \
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
    echo "shell:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  program: /bin/zsh" >> /etc/skel/.config/alacritty/alacritty.yml && \
    # Create Neofetch config
    mkdir -p /etc/skel/.config/neofetch && \
    echo "# Neofetch Configuration" > /etc/skel/.config/neofetch/config.conf && \
    echo "print_info() {" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info title" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info underline" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"OS\" distro" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Host\" model" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Kernel\" kernel" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Uptime\" uptime" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Packages\" packages" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Shell\" shell" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"DE\" de" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"WM\" wm" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Terminal\" term" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"CPU\" cpu" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Memory\" memory" >> /etc/skel/.config/neofetch/config.conf && \
    echo "    info \"Disk\" disk" >> /etc/skel/.config/neofetch/config.conf && \
    echo "}" >> /etc/skel/.config/neofetch/config.conf && \
    echo "# Set small logo" >> /etc/skel/.config/neofetch/config.conf && \
    echo "ascii_distro=\"auto\"" >> /etc/skel/.config/neofetch/config.conf && \
    echo "ascii_colors=(distro)" >> /etc/skel/.config/neofetch/config.conf && \
    echo "ascii_bold=\"on\"" >> /etc/skel/.config/neofetch/config.conf && \
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
    # Create Neovim config
    mkdir -p /etc/skel/.config/nvim && \
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
    # Create bash profile for fallback
    echo "# .bash_profile" > /etc/skel/.bash_profile && \
    echo "if [ -f ~/.bashrc ]; then" >> /etc/skel/.bash_profile && \
    echo "    . ~/.bashrc" >> /etc/skel/.bash_profile && \
    echo "fi" >> /etc/skel/.bash_profile && \
    # Create better bashrc without the "command not found" error
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
    echo "# Run fastfetch if available" >> /etc/skel/.bashrc && \
    echo "if command -v fastfetch &> /dev/null; then" >> /etc/skel/.bashrc && \
    echo "    fastfetch" >> /etc/skel/.bashrc && \
    echo "elif command -v neofetch &> /dev/null; then" >> /etc/skel/.bashrc && \
    echo "    neofetch" >> /etc/skel/.bashrc && \
    echo "fi" >> /etc/skel/.bashrc && \
    # Set Chromium as default browser
    echo "[Default Applications]" > /etc/skel/.config/mimeapps.list && \
    echo "text/html=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/http=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/https=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list

# ==========================================
# SECTION 10: DESKTOP SESSION SETUP
# ==========================================
# Configure desktop environment settings
RUN mkdir -p /etc/skel/.config/autostart && \
    # Create autostart file for NetworkManager applet
    echo "[Desktop Entry]" > /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Type=Application" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Name=Network Manager Applet" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Exec=nm-applet --indicator" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    echo "Terminal=false" >> /etc/skel/.config/autostart/nm-applet.desktop && \
    # Create environment variables
    mkdir -p /etc/environment.d && \
    echo "# COSMIC environment variables" > /etc/environment.d/90-cosmic-env.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "XDG_CURRENT_DESKTOP=cosmic" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "XDG_SESSION_DESKTOP=cosmic" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "QT_QPA_PLATFORM=wayland" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "QT_AUTO_SCREEN_SCALE_FACTOR=1" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "SDL_VIDEODRIVER=wayland" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "CLUTTER_BACKEND=wayland" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "_JAVA_AWT_WM_NONREPARENTING=1" >> /etc/environment.d/90-cosmic-env.conf && \
    echo "ZDOTDIR=\$HOME" >> /etc/environment.d/90-cosmic-env.conf && \
    # Create session files
    mkdir -p /usr/share/wayland-sessions && \
    mkdir -p /usr/share/xsessions && \
    # Create COSMIC Wayland session file
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Name=COSMIC" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Comment=This session logs you into COSMIC" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Exec=cosmic-session" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "DesktopNames=cosmic" >> /usr/share/wayland-sessions/cosmic.desktop && \
    chmod 644 /usr/share/wayland-sessions/cosmic.desktop && \
    # Create GNOME fallback session file
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/gnome.desktop && \
    echo "Name=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Exec=gnome-session" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    chmod 644 /usr/share/wayland-sessions/gnome.desktop && \
    # Create welcome message script that doesn't have command not found error
    echo '#!/bin/bash' > /etc/profile.d/welcome.sh && \
    echo 'if [ -f /etc/motd ]; then' >> /etc/profile.d/welcome.sh && \
    echo '    cat /etc/motd' >> /etc/profile.d/welcome.sh && \
    echo 'fi' >> /etc/profile.d/welcome.sh && \
    chmod +x /etc/profile.d/welcome.sh

# ==========================================
# SECTION 11: FIRST-BOOT SETUP
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "Description=First Boot Setup for Orb OS COSMIC" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "Before=display-manager.service" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "After=network.target" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "ExecStart=/usr/bin/orb-cosmic-firstboot.sh" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/orb-cosmic-firstboot.service && \
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Ensure GDM is enabled" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "systemctl enable gdm.service" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "systemctl set-default graphical.target" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Set zsh as default shell for future users" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Configure neofetch as fallback for fastfetch" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "if ! command -v fastfetch &> /dev/null && command -v neofetch &> /dev/null; then" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    ln -sf /usr/bin/neofetch /usr/local/bin/fastfetch 2>/dev/null || true" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Set up Node.js global packages" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "if command -v npm &> /dev/null; then" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    npm install -g yarn typescript ts-node" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Set up Python global packages" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "if command -v pip3 &> /dev/null; then" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    pip3 install --upgrade pip" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    pip3 install virtualenv black flake8 mypy pytest" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/orb-cosmic-firstboot.sh && \
    echo "systemctl disable orb-cosmic-firstboot.service" >> /usr/bin/orb-cosmic-firstboot.sh && \
    chmod +x /usr/bin/orb-cosmic-firstboot.sh && \
    systemctl enable orb-cosmic-firstboot.service

# Copy override files and configure the system
COPY override /

# ==========================================
# SECTION 12: OS BRANDING
# ==========================================
# Update OS branding
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Update system branding
    sed -i 's/Kinoite/Orb OS/g' /etc/os-release && \
    sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="Orb OS COSMIC"/' /etc/os-release && \
    sed -i 's/NAME=.*/NAME="Orb OS"/' /etc/os-release && \
    sed -i 's/ID=.*/ID=orb-os/' /etc/os-release && \
    # Add custom variant information
    echo "VARIANT_ID=cosmic" >> /etc/os-release && \
    echo "VARIANT=COSMIC" >> /etc/os-release && \
    # Create version file
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC" > /etc/orb-os/version && \
    # Update welcome message
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release

# Final systemd configuration to ensure graphical boot
RUN systemctl set-default graphical.target && \
    systemctl enable gdm.service
