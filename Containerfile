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
# Install desktop environment core
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install GNOME shell and session manager
    rpm-ostree install -y \
    gdm \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-terminal \
    gnome-backgrounds \
    gnome-shell-extension-appindicator \
    nautilus \
    xdg-user-dirs \
    xdg-user-dirs-gtk \
    || true && \
    # Fix systemd targets for graphical login
    ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target && \
    systemctl enable gdm.service && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: ADDITIONAL GNOME PACKAGES
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install additional GNOME packages
    rpm-ostree install -y \
    gnome-tweaks \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-user-theme \
    gnome-console \
    gnome-software \
    gnome-system-monitor \
    || true && \
    # Install core themes and icons
    rpm-ostree install -y \
    adwaita-gtk2-theme \
    adwaita-icon-theme \
    hicolor-icon-theme \
    papirus-icon-theme \
    arc-theme \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 5: DESKTOP ENVIRONMENT COMPONENTS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install desktop environment components
    rpm-ostree install -y \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    polkit-gnome \
    gnome-keyring \
    gsettings-desktop-schemas \
    alacritty \
    chromium \
    || true && \
    # Install display and graphics packages
    rpm-ostree install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    mesa-libGLU \
    libglvnd-glx \
    libglvnd-opengl \
    libglvnd-gles \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber \
    || true && \
    # Install network components
    rpm-ostree install -y \
    NetworkManager-wifi \
    network-manager-applet \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 6: DEVELOPMENT TOOLS
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install development tools
    rpm-ostree install -y \
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
    neovim \
    nodejs \
    npm \
    golang \
    python3 \
    python3-pip \
    python3-devel \
    || true && \
    # Additional utilities
    rpm-ostree install -y \
    tmux \
    btop \
    fastfetch \
    ghostty \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 7: FONTS AND APPEARANCE
# ==========================================
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install fonts 
    rpm-ostree install -y \
    google-noto-sans-fonts \
    google-noto-serif-fonts \
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    dejavu-sans-fonts \
    dejavu-sans-mono-fonts \
    dejavu-serif-fonts \
    inter-fonts \
    jetbrains-mono-fonts \
    fontawesome-fonts \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 8: USER CONFIGURATION
# ==========================================
# Set up user configuration files
RUN mkdir -p /etc/skel/.config && \
    # Create terminal configs
    mkdir -p /etc/skel/.config/alacritty && \
    echo "window:" > /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  padding:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    x: 10" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    y: 10" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  opacity: 0.9" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "font:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  normal:" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "    family: JetBrains Mono" >> /etc/skel/.config/alacritty/alacritty.yml && \
    echo "  size: 11.0" >> /etc/skel/.config/alacritty/alacritty.yml && \
    # Create autostart directory
    mkdir -p /etc/skel/.config/autostart && \
    # Create neovim config
    mkdir -p /etc/skel/.config/nvim && \
    echo "vim.opt.number = true" > /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.relativenumber = true" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.tabstop = 2" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.shiftwidth = 2" >> /etc/skel/.config/nvim/init.lua && \
    echo "vim.opt.expandtab = true" >> /etc/skel/.config/nvim/init.lua && \
    # Set default browser
    mkdir -p /etc/skel/.config && \
    echo "[Default Applications]" > /etc/skel/.config/mimeapps.list && \
    echo "text/html=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/http=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/https=chromium-browser.desktop" >> /etc/skel/.config/mimeapps.list && \
    # Create bash profile
    echo "# .bash_profile" > /etc/skel/.bash_profile && \
    echo "if [ -f ~/.bashrc ]; then" >> /etc/skel/.bash_profile && \
    echo "  . ~/.bashrc" >> /etc/skel/.bash_profile && \
    echo "fi" >> /etc/skel/.bash_profile && \
    # Create bashrc
    echo "# .bashrc" > /etc/skel/.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/skel/.bashrc && \
    echo "alias ll='ls -la'" >> /etc/skel/.bashrc && \
    echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/skel/.bashrc

# ==========================================
# SECTION 9: GNOME SETTINGS
# ==========================================
# Create dconf database with COSMIC-like settings
RUN mkdir -p /etc/dconf/profile && \
    echo "user-db:user" > /etc/dconf/profile/user && \
    echo "system-db:local" >> /etc/dconf/profile/user && \
    mkdir -p /etc/dconf/db/local.d && \
    # Interface settings
    echo "[org/gnome/desktop/interface]" > /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "gtk-theme='Arc-Dark'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "icon-theme='Papirus-Dark'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "cursor-theme='Adwaita'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "font-name='Inter 11'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "document-font-name='Inter 11'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "monospace-font-name='JetBrains Mono 11'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "color-scheme='prefer-dark'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "enable-animations=true" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "enable-hot-corners=true" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    # Window manager settings
    echo "[org/gnome/desktop/wm/preferences]" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "button-layout=':minimize,maximize,close'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "focus-mode='click'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "workspace-names=['Main', 'Work', 'Media', 'Other']" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    # Shell settings
    echo "[org/gnome/shell]" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'appindicatorsupport@rgcjonas.gmail.com', 'user-theme@gnome-shell-extensions.gcampax.github.com']" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "favorite-apps=['chromium-browser.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop']" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    # Dash to Dock settings
    echo "[org/gnome/shell/extensions/dash-to-dock]" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "dock-fixed=true" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "dock-position='BOTTOM'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "extend-height=false" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "transparency-mode='FIXED'" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "background-opacity=0.8" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    # Mutter settings
    echo "[org/gnome/mutter]" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "dynamic-workspaces=true" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    echo "edge-tiling=true" >> /etc/dconf/db/local.d/00-cosmic-theme && \
    dconf update || true

# ==========================================
# SECTION 10: SESSION CONFIGURATION
# ==========================================
# Configure desktop environment settings
RUN mkdir -p /usr/share/wayland-sessions && \
    # Create GNOME Wayland session file
    echo "[Desktop Entry]" > /usr/share/wayland-sessions/gnome.desktop && \
    echo "Name=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Exec=gnome-session" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "Type=Application" >> /usr/share/wayland-sessions/gnome.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/wayland-sessions/gnome.desktop && \
    chmod +x /usr/share/wayland-sessions/gnome.desktop && \
    # Create GNOME fallback session file
    mkdir -p /usr/share/xsessions && \
    echo "[Desktop Entry]" > /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Name=GNOME on Xorg" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Comment=This session logs you into GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Exec=gnome-session" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "Type=Application" >> /usr/share/xsessions/gnome-xorg.desktop && \
    echo "DesktopNames=GNOME" >> /usr/share/xsessions/gnome-xorg.desktop && \
    chmod +x /usr/share/xsessions/gnome-xorg.desktop && \
    # Configure environment variables
    mkdir -p /etc/environment.d && \
    echo "# Wayland and X11 compatibility" > /etc/environment.d/99-env.conf && \
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment.d/99-env.conf && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment.d/99-env.conf && \
    echo "XDG_CURRENT_DESKTOP=GNOME" >> /etc/environment.d/99-env.conf && \
    echo "XDG_SESSION_DESKTOP=gnome" >> /etc/environment.d/99-env.conf

# ==========================================
# SECTION 11: FIRSTBOOT SETUP
# ==========================================
# Create a first-boot script to complete setup
RUN mkdir -p /usr/lib/systemd/system && \
    # Create first boot service
    echo "[Unit]" > /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Description=First boot setup for Orb OS COSMIC" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Wants=network-online.target" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "After=network-online.target" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "ConditionFirstBoot=yes" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "[Service]" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Type=oneshot" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "ExecStart=/usr/bin/orb-firstboot.sh" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "RemainAfterExit=yes" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "[Install]" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/orb-firstboot.service && \
    # Create first boot script
    mkdir -p /usr/bin && \
    echo "#!/bin/bash" > /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Make sure GDM is enabled and set as default target" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl enable gdm.service" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl set-default graphical.target" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Update dconf database" >> /usr/bin/orb-firstboot.sh && \
    echo "dconf update" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Update user directories" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Desktop" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Documents" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Downloads" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Music" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Pictures" >> /usr/bin/orb-firstboot.sh && \
    echo "mkdir -p /etc/skel/Videos" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Check for NVIDIA hardware and install drivers if needed" >> /usr/bin/orb-firstboot.sh && \
    echo "if lspci | grep -i nvidia > /dev/null; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    echo \"NVIDIA GPU detected, installing drivers...\"" >> /usr/bin/orb-firstboot.sh && \
    echo "    rpm-ostree install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl disable orb-firstboot.service" >> /usr/bin/orb-firstboot.sh && \
    chmod +x /usr/bin/orb-firstboot.sh && \
    systemctl enable orb-firstboot.service

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
    echo "Current User: Ariffansyah" >> /etc/os-release && \
    # Create custom branding files
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC - 2025-05-09 12:07:27" > /etc/orb-os/version && \
    # Update welcome and issue files
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC-like desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release

# Ensure GDM is enabled and set as default target
RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target
