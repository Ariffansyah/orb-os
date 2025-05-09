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
    # Add System76 COSMIC repository - using POP OS repo which has COSMIC packages
    echo "[pop-os]" > /etc/yum.repos.d/pop-os.repo && \
    echo "name=Pop_OS Repository" >> /etc/yum.repos.d/pop-os.repo && \
    echo "baseurl=http://apt.pop-os.org/release" >> /etc/yum.repos.d/pop-os.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/pop-os.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/pop-os.repo && \
    echo "skip_if_unavailable=True" >> /etc/yum.repos.d/pop-os.repo && \
    # Add GDM for login screen
    dnf install -y gdm && \
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
# Install Pop!_OS repository key
RUN curl -fsSL https://apt.pop-os.org/archive-keyring/public-key.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pop-os-archive.gpg

# Install COSMIC and dependencies
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install essential display packages
    rpm-ostree install \
    gdm \
    switcheroo-control \
    libglvnd \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    || true && \
    rpm-ostree install \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    || true && \
    # Install COSMIC packages if available or fallback to GNOME
    (rpm-ostree install \
    pop-cosmic \
    pop-desktop \
    pop-default-settings \
    pop-gnome-shell-theme \
    cosmic-comp \
    cosmic-session \
    || true) && \
    # Install core desktop environment requirements
    rpm-ostree install \
    wl-clipboard \
    gtk3-devel \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    polkit-gnome \
    || true && \
    # Fonts and themes
    rpm-ostree install \
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    || true && \
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
    # Bluetooth
    rpm-ostree install \
    bluez \
    bluez-tools \
    blueman \
    || true && \
    # Network
    rpm-ostree install \
    NetworkManager-wifi \
    network-manager-applet \
    || true && \
    # Python dependencies
    rpm-ostree install \
    python3-cairo \
    python-cairo \
    pipx \
    || true && \
    # System utilities
    rpm-ostree install \
    polkit-qt6-1 \
    lsd \
    fastfetch \
    tmux \
    neofetch \
    || true && \
    # Text editors
    rpm-ostree install \
    neovim \
    || true && \
    # Terminal and Browser
    rpm-ostree install \
    ghostty \
    alacritty \
    gnome-terminal \
    chromium \
    || true && \
    # Icon themes
    rpm-ostree install \
    papirus-icon-theme \
    adwaita-icon-theme \
    || true && \
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
# SECTION 5: DESKTOP ENVIRONMENT SETUP
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
    # System integration
    polkit-kde \
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
    nautilus \
    kde-cli-tools \
    # Additional utilities
    btop \
    || true && \
    # Enable GDM
    systemctl enable gdm.service && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DESKTOP CONFIGURATION
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
    echo "# Desktop environment variables" > /etc/environment.d/90-desktop-env.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_CURRENT_DESKTOP=pop:GNOME" >> /etc/environment.d/90-desktop-env.conf && \
    echo "XDG_SESSION_DESKTOP=pop" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_QPA_PLATFORM=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "QT_AUTO_SCREEN_SCALE_FACTOR=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "SDL_VIDEODRIVER=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "CLUTTER_BACKEND=wayland" >> /etc/environment.d/90-desktop-env.conf && \
    echo "_JAVA_AWT_WM_NONREPARENTING=1" >> /etc/environment.d/90-desktop-env.conf && \
    echo "GOPATH=/usr/local/go" >> /etc/environment.d/90-desktop-env.conf && \
    echo "PATH=$PATH:/usr/local/go/bin" >> /etc/environment.d/90-desktop-env.conf && \
    # Create desktop session files
    mkdir -p /usr/share/wayland-sessions && \
    mkdir -p /usr/share/xsessions && \
    # Create GNOME Wayland session file as fallback
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/gnome-wayland.desktop && \
    echo "Name=GNOME on Wayland" >> /usr/share/wayland-sessions/gnome-wayland.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/wayland-sessions/gnome-wayland.desktop && \
    echo "Exec=gnome-session" >> /usr/share/wayland-sessions/gnome-wayland.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/gnome-wayland.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/wayland-sessions/gnome-wayland.desktop && \
    # Try to create Pop OS session if cosmic packages were installed
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/pop.desktop && \
    echo "Name=Pop" >> /usr/share/wayland-sessions/pop.desktop && \
    echo "Comment=Pop!_OS with COSMIC desktop" >> /usr/share/wayland-sessions/pop.desktop && \
    echo "Exec=gnome-session --session=pop" >> /usr/share/wayland-sessions/pop.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/pop.desktop && \
    echo "DesktopNames=pop:GNOME" >> /usr/share/wayland-sessions/pop.desktop && \
    # Also create X11 session as fallback
    echo "[Desktop Entry]" > /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Name=GNOME on Xorg" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Exec=gnome-session" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Type=Application" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    # Enable Redis service
    systemctl enable redis.service || true && \
    # Ensure files are accessible
    chmod 755 /usr/share/wayland-sessions/*.desktop && \
    chmod 755 /usr/share/xsessions/*.desktop && \
    # Final cleanup
    if [ -x /usr/libexec/build/image-info ]; then /usr/libexec/build/image-info; fi && \
    if [ -x /usr/libexec/build/build-initramfs ]; then /usr/libexec/build/build-initramfs; fi && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp

# ==========================================
# SECTION 8: GNOME/COSMIC THEME SETUP
# ==========================================
RUN mkdir -p /etc/dconf/db/local.d && \
    # Create theme settings
    echo "[org/gnome/desktop/interface]" > /etc/dconf/db/local.d/01-theme && \
    echo "gtk-theme='Pop'" >> /etc/dconf/db/local.d/01-theme && \
    echo "icon-theme='Pop'" >> /etc/dconf/db/local.d/01-theme && \
    echo "cursor-theme='Pop'" >> /etc/dconf/db/local.d/01-theme && \
    echo "font-name='Inter 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "document-font-name='Inter 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "monospace-font-name='JetBrainsMono Nerd Font 11'" >> /etc/dconf/db/local.d/01-theme && \
    echo "color-scheme='prefer-dark'" >> /etc/dconf/db/local.d/01-theme && \
    echo "" >> /etc/dconf/db/local.d/01-theme && \
    echo "[org/gnome/shell]" >> /etc/dconf/db/local.d/01-theme && \
    echo "enabled-extensions=['pop-cosmic@system76.com', 'cosmic-dock@system76.com', 'cosmic-workspaces@system76.com']" >> /etc/dconf/db/local.d/01-theme && \
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
    # Update dconf database
    dconf update || true

# ==========================================
# SECTION 9: FIRST-BOOT SETUP SCRIPT
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Description=Configure Orb OS COSMIC on First Boot" >> /usr/lib/systemd/system/orb-firstboot.service && \
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
    echo "# Create a script to check for NVIDIA and install drivers if needed" >> /usr/bin/orb-firstboot.sh && \
    echo "if lspci -k | grep -A 2 -E \"(VGA|3D)\" | grep -iq nvidia; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/orb-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Update dconf database" >> /usr/bin/orb-firstboot.sh && \
    echo "dconf update" >> /usr/bin/orb-firstboot.sh && \
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
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC - 2025-05-09 10:47:24" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release
