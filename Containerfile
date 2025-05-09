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
    https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo \
    https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    # Add System76 COSMIC repository (manual creation since direct URL doesn't work)
    echo "[system76-cosmic]" > /etc/yum.repos.d/system76-cosmic.repo && \
    echo "name=System76 COSMIC for Fedora \$releasever" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "baseurl=https://download.opensuse.org/repositories/home:/system76:/cosmic/Fedora_\$releasever/" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/system76-cosmic.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/system76-cosmic.repo && \
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
# SECTION 3: COSMIC & DEPENDENCIES INSTALLATION
# ==========================================
# Install COSMIC and dependencies
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    # Core COSMIC packages
    cosmic-desktop \
    cosmic-session \
    cosmic-applets \
    cosmic-panel \
    cosmic-launcher \
    cosmic-settings \
    cosmic-workspaces \
    || true && \
    rpm-ostree install \
    # More COSMIC components
    cosmic-greeter \
    cosmic-bg \
    cosmic-comp \
    cosmic-osd \
    cosmic-notifications \
    cosmic-applibrary \
    cosmic-icons \
    cosmic-files \
    cosmic-term \
    || true && \
    rpm-ostree install \
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
    # Browser
    chromium \
    # Icon themes
    papirus-icon-theme \
    # Fonts
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
# SECTION 5: COSMIC APPS & ENVIRONMENT
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
    grim \
    slurp \
    # System integration
    polkit-kde \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-cosmic \
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
    # Additional utilities
    btop \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: COSMIC CONFIGURATION
# ==========================================
# Set up the COSMIC configuration
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
    # Final cleanup
    ostree container commit

# ==========================================
# SECTION 7: ADDITIONAL CONFIG & BOOT SETUP
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
    echo "# COSMIC environment variables" > /etc/environment.d/90-cosmic.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/90-cosmic.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/90-cosmic.conf && \
    echo "XDG_CURRENT_DESKTOP=COSMIC" >> /etc/environment.d/90-cosmic.conf && \
    echo "XDG_SESSION_DESKTOP=COSMIC" >> /etc/environment.d/90-cosmic.conf && \
    echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment.d/90-cosmic.conf && \
    echo "QT_QPA_PLATFORM=wayland" >> /etc/environment.d/90-cosmic.conf && \
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> /etc/environment.d/90-cosmic.conf && \
    echo "QT_AUTO_SCREEN_SCALE_FACTOR=1" >> /etc/environment.d/90-cosmic.conf && \
    echo "SDL_VIDEODRIVER=wayland" >> /etc/environment.d/90-cosmic.conf && \
    echo "CLUTTER_BACKEND=wayland" >> /etc/environment.d/90-cosmic.conf && \
    echo "_JAVA_AWT_WM_NONREPARENTING=1" >> /etc/environment.d/90-cosmic.conf && \
    echo "GOPATH=/usr/local/go" >> /etc/environment.d/90-cosmic.conf && \
    echo "PATH=$PATH:/usr/local/go/bin" >> /etc/environment.d/90-cosmic.conf && \
    # Create COSMIC session file
    mkdir -p /usr/share/wayland-sessions && \
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Name=COSMIC" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Comment=System76 COSMIC Desktop Environment" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Exec=cosmic-session" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/cosmic.desktop && \
    echo "DesktopNames=COSMIC" >> /usr/share/wayland-sessions/cosmic.desktop && \
    # Enable cosmic-greeter service if it exists
    (systemctl enable cosmic-greeter.service 2>/dev/null || true) && \
    # Enable Redis service
    systemctl enable redis.service || true && \
    # Ensure files are accessible
    chmod 755 /usr/share/wayland-sessions/cosmic.desktop && \
    # Remove Plasma sessions if they exist
    rm -f /usr/share/wayland-sessions/plasmawayland.desktop 2>/dev/null || true && \
    rm -f /usr/share/xsessions/plasma.desktop 2>/dev/null || true && \
    # Final cleanup
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit

# ==========================================
# SECTION 8: COSMIC THEME SETUP
# ==========================================
RUN mkdir -p /etc/cosmic-theme && \
    echo "{" > /etc/cosmic-theme/config.json && \
    echo "  \"accent_color\": \"#6a92d7\"," >> /etc/cosmic-theme/config.json && \
    echo "  \"theme_type\": \"dark\"" >> /etc/cosmic-theme/config.json && \
    echo "}" >> /etc/cosmic-theme/config.json && \
    # Create default COSMIC greeting configuration if needed
    mkdir -p /etc/cosmic-greeter 2>/dev/null || true && \
    echo "{" > /etc/cosmic-greeter/config.json 2>/dev/null || true && \
    echo "  \"background_mode\": \"Solid\"," >> /etc/cosmic-greeter/config.json 2>/dev/null || true && \
    echo "  \"background_solid_color\": \"#282c34\"," >> /etc/cosmic-greeter/config.json 2>/dev/null || true && \
    echo "  \"time_format\": \"12Hour\"" >> /etc/cosmic-greeter/config.json 2>/dev/null || true && \
    echo "}" >> /etc/cosmic-greeter/config.json 2>/dev/null || true && \
    ostree container commit

# ==========================================
# SECTION 9: FIRST-BOOT SETUP SCRIPT
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "Description=Configure COSMIC on First Boot" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "After=network.target" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "ExecStart=/usr/bin/cosmic-firstboot.sh" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/cosmic-firstboot.service && \
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Setup programming language environments" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Set up Node.js global packages" >> /usr/bin/cosmic-firstboot.sh && \
    echo "npm install -g yarn typescript ts-node nodemon" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Set up Python global packages" >> /usr/bin/cosmic-firstboot.sh && \
    echo "pip3 install --upgrade pip" >> /usr/bin/cosmic-firstboot.sh && \
    echo "pip3 install virtualenv black flake8 mypy pytest jupyter" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Set up Go environment" >> /usr/bin/cosmic-firstboot.sh && \
    echo "mkdir -p /usr/local/go" >> /usr/bin/cosmic-firstboot.sh && \
    echo "echo 'export GOPATH=/usr/local/go' >> /etc/profile.d/go.sh" >> /usr/bin/cosmic-firstboot.sh && \
    echo "echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh" >> /usr/bin/cosmic-firstboot.sh && \
    echo "chmod +x /etc/profile.d/go.sh" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Set up Neovim plugins" >> /usr/bin/cosmic-firstboot.sh && \
    echo "mkdir -p /etc/skel/.local/share/nvim/site/pack/packer/start" >> /usr/bin/cosmic-firstboot.sh && \
    echo "git clone --depth 1 https://github.com/wbthomason/packer.nvim /etc/skel/.local/share/nvim/site/pack/packer/start/packer.nvim" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Setup Redis service" >> /usr/bin/cosmic-firstboot.sh && \
    echo "if command -v redis-server &> /dev/null; then" >> /usr/bin/cosmic-firstboot.sh && \
    echo "    systemctl enable redis" >> /usr/bin/cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/cosmic-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/cosmic-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/cosmic-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/cosmic-firstboot.sh && \
    echo "fi" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Configure default browser" >> /usr/bin/cosmic-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.bashrc" >> /usr/bin/cosmic-firstboot.sh && \
    echo "echo 'xdg-settings set default-web-browser chromium-browser.desktop' >> /etc/skel/.zshrc" >> /usr/bin/cosmic-firstboot.sh && \
    echo "" >> /usr/bin/cosmic-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/cosmic-firstboot.sh && \
    echo "systemctl disable cosmic-firstboot.service" >> /usr/bin/cosmic-firstboot.sh && \
    chmod +x /usr/bin/cosmic-firstboot.sh && \
    systemctl enable cosmic-firstboot.service && \
    ostree container commit

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
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC - 2025-05-09 09:53:59" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release
