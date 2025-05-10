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
ARG STELLARITE_VERSION="0.1.0"
ARG STELLARITE_ARCH="x86_64"

COPY system /

# ==========================================
# SECTION 1: Remove and Modify Base Packages
# ==========================================

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    firefox \
    firefox-langpacks \
    || true && \
    rpm-ostree cleanup -m \
    && ostree container commit

# ==========================================
# SECTION 2: Add Repositories
# ==========================================

RUN curl -s https://copr.fedorainfracloud.org/coprs/agriffis/neovim-nightly/repo/fedora-$(rpm -E %fedora)/agriffis-neovim-nightly-fedora-$(rpm -E %fedora).repo > /etc/yum.repos.d/agriffis-neovim-nightly-fedora.repo \
    && curl -s https://download.opensuse.org/repositories/home:/dkalev:/hyprland/Fedora_$(rpm -E %fedora)/home:dkalev:hyprland.repo > /etc/yum.repos.d/hyprland.repo \
    && curl -s https://get.zenith.fedorapeople.org/zenith.repo > /etc/yum.repos.d/zen-browser.repo \
    && ostree container commit

# ==========================================
# SECTION 3: Install Base RPM Packages
# ==========================================

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    alacritty \
    appstream-data \
    btop \
    corectrl \
    curl \
    exa \
    fastfetch \
    ghostty \
    git \
    glibc-langpack-en \
    kmod-winesync \
    make \
    ncurses \
    neofetch \
    neovim \
    NetworkManager-tui \
    NetworkManager-wifi \
    nodejs \
    npm \
    p7zip \
    p7zip-plugins \
    python3-pip \
    qemu \
    ripgrep \
    rsync \
    starship \
    stow \
    tar \
    tldr \
    unrar \
    unzip \
    vim \
    wget \
    wireplumber \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    zenith \
    zsh \
    && ostree container commit

# ==========================================
# SECTION 3.1: Additional Components
# ==========================================

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install -y \
    gdm \
    lightdm \
    bluez \
    bluez-tools \
    NetworkManager-wifi \
    network-manager-applet \
    || true && \
    systemctl set-default graphical.target && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 3.2: FASTFETCH SETUP
# ==========================================
# Ensure fastfetch is properly installed and configured
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    # Install fastfetch
    rpm-ostree install -y fastfetch && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

# ==========================================
# SECTION 4: Configure ZSH
# ==========================================

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
    echo "# Use starship prompt if available" >> /etc/skel/.zshrc && \
    echo "if command -v starship &> /dev/null; then" >> /etc/skel/.zshrc && \
    echo "    eval \"\$(starship init zsh)\"" >> /etc/skel/.zshrc && \
    echo "else" >> /etc/skel/.zshrc && \
    echo "    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '" >> /etc/skel/.zshrc && \
    echo "fi" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Aliases" >> /etc/skel/.zshrc && \
    echo "alias ls='exa --icons'" >> /etc/skel/.zshrc && \
    echo "alias ll='exa --long --icons --header'" >> /etc/skel/.zshrc && \
    echo "alias la='exa --long --all --icons --header'" >> /etc/skel/.zshrc && \
    echo "alias lt='exa --tree --icons'" >> /etc/skel/.zshrc && \
    echo "alias grep='grep --color=auto'" >> /etc/skel/.zshrc && \
    echo "alias vim='nvim'" >> /etc/skel/.zshrc && \
    echo "alias v='nvim'" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Run fastfetch on terminal start" >> /etc/skel/.zshrc && \
    echo "fastfetch" >> /etc/skel/.zshrc && \
    echo "" >> /etc/skel/.zshrc && \
    echo "# Welcome message" >> /etc/skel/.zshrc && \
    echo "cat << 'EOF'" >> /etc/skel/.zshrc && \
    echo "Welcome to Orb OS: Terminal Edition" >> /etc/skel/.zshrc && \
    echo "Type 'starship init' to initialize the starship prompt." >> /etc/skel/.zshrc && \
    echo "EOF" >> /etc/skel/.zshrc && \
    # Create .zshenv file
    echo "# ZSH Environment" > /etc/skel/.zshenv && \
    echo "" >> /etc/skel/.zshenv && \
    echo "# Set PATH" >> /etc/skel/.zshenv && \
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> /etc/skel/.zshenv && \
    echo "" >> /etc/skel/.zshenv

# ==========================================
# SECTION 5: Configure Bash (Fallback)
# ==========================================

RUN echo "# .bash_profile" > /etc/skel/.bash_profile && \
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
    echo "if command -v exa &> /dev/null; then" >> /etc/skel/.bashrc && \
    echo "    alias ls='exa --icons'" >> /etc/skel/.bashrc && \
    echo "    alias ll='exa --long --icons --header'" >> /etc/skel/.bashrc && \
    echo "    alias la='exa --long --all --icons --header'" >> /etc/skel/.bashrc && \
    echo "    alias lt='exa --tree --icons'" >> /etc/skel/.bashrc && \
    echo "else" >> /etc/skel/.bashrc && \
    echo "    alias ls='ls --color=auto'" >> /etc/skel/.bashrc && \
    echo "    alias ll='ls -la'" >> /etc/skel/.bashrc && \
    echo "fi" >> /etc/skel/.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/skel/.bashrc && \
    echo "alias vim='nvim'" >> /etc/skel/.bashrc && \
    echo "alias v='nvim'" >> /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# Set prompt" >> /etc/skel/.bashrc && \
    echo "if command -v starship &> /dev/null; then" >> /etc/skel/.bashrc && \
    echo "    eval \"\$(starship init bash)\"" >> /etc/skel/.bashrc && \
    echo "else" >> /etc/skel/.bashrc && \
    echo "    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/skel/.bashrc && \
    echo "fi" >> /etc/skel/.bashrc && \
    echo "" >> /etc/skel/.bashrc && \
    echo "# Run fastfetch on terminal start" >> /etc/skel/.bashrc && \
    echo "fastfetch" >> /etc/skel/.bashrc && \
    # Set Zen Browser as default browser
    mkdir -p /etc/skel/.config && \
    echo "[Default Applications]" > /etc/skel/.config/mimeapps.list && \
    echo "text/html=org.mozilla.zenith.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/http=org.mozilla.zenith.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/https=org.mozilla.zenith.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/about=org.mozilla.zenith.desktop" >> /etc/skel/.config/mimeapps.list && \
    echo "x-scheme-handler/unknown=org.mozilla.zenith.desktop" >> /etc/skel/.config/mimeapps.list

# ==========================================
# SECTION 6: FIRST-BOOT SETUP
# ==========================================

RUN mkdir -p /usr/lib/systemd/system && \
    echo "[Unit]" > /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Description=First Boot Setup for Orb OS" >> /usr/lib/systemd/system/orb-firstboot.service && \
    echo "Before=display-manager.service" >> /usr/lib/systemd/system/orb-firstboot.service && \
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
    echo "# Ensure display manager is enabled" >> /usr/bin/orb-firstboot.sh && \
    echo "if [ -f /usr/lib/systemd/system/gdm.service ]; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    systemctl enable gdm.service" >> /usr/bin/orb-firstboot.sh && \
    echo "elif [ -f /usr/lib/systemd/system/lightdm.service ]; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    systemctl enable lightdm.service" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl set-default graphical.target" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set zsh as default shell for future users" >> /usr/bin/orb-firstboot.sh && \
    echo "sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Set Zen Browser as default browser" >> /usr/bin/orb-firstboot.sh && \
    echo "if command -v zenith &> /dev/null; then" >> /usr/bin/orb-firstboot.sh && \
    echo "    xdg-settings set default-web-browser org.mozilla.zenith.desktop 2>/dev/null || true" >> /usr/bin/orb-firstboot.sh && \
    echo "fi" >> /usr/bin/orb-firstboot.sh && \
    echo "" >> /usr/bin/orb-firstboot.sh && \
    echo "# Disable this service after first run" >> /usr/bin/orb-firstboot.sh && \
    echo "systemctl disable orb-firstboot.service" >> /usr/bin/orb-firstboot.sh && \
    chmod +x /usr/bin/orb-firstboot.sh && \
    systemctl enable orb-firstboot.service

# ==========================================
# SECTION 7: Configure Terminal Apps
# ==========================================

# Configure Alacritty
RUN mkdir -p /etc/skel/.config/alacritty && \
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
    echo "  program: /bin/zsh" >> /etc/skel/.config/alacritty/alacritty.yml

# Configure Ghostty
RUN mkdir -p /etc/skel/.config/ghostty && \
    echo "# Ghostty Terminal Configuration" > /etc/skel/.config/ghostty/config && \
    echo "theme = catppuccin-mocha" >> /etc/skel/.config/ghostty/config && \
    echo "font-family = JetBrainsMono Nerd Font" >> /etc/skel/.config/ghostty/config && \
    echo "font-size = 12" >> /etc/skel/.config/ghostty/config && \
    echo "cursor-style = beam" >> /etc/skel/.config/ghostty/config && \
    echo "background-opacity = 0.95" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-x = 10" >> /etc/skel/.config/ghostty/config && \
    echo "window-padding-y = 10" >> /etc/skel/.config/ghostty/config && \
    echo "shell = /bin/zsh" >> /etc/skel/.config/ghostty/config

# Configure Starship prompt
RUN mkdir -p /etc/skel/.config && \
    echo '# Starship Configuration' > /etc/skel/.config/starship.toml && \
    echo '[character]' >> /etc/skel/.config/starship.toml && \
    echo 'success_symbol = "[➜](bold green)"' >> /etc/skel/.config/starship.toml && \
    echo 'error_symbol = "[✗](bold red)"' >> /etc/skel/.config/starship.toml

# ==========================================
# SECTION 8: FASTFETCH SETUP
# ==========================================
# Ensure fastfetch is properly installed and configured
RUN mkdir -p /etc/skel/.config/fastfetch && \
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
    echo '        "terminal",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "cpu",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "memory",' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '        "disk"' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '    ]' >> /etc/skel/.config/fastfetch/config.jsonc && \
    echo '}' >> /etc/skel/.config/fastfetch/config.jsonc && \
    # Create system config
    mkdir -p /etc/fastfetch && \
    cp /etc/skel/.config/fastfetch/config.jsonc /etc/fastfetch/

# ==========================================
# SECTION 9: OS BRANDING
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
    echo "CURRENT_USER=Ariffansyah" >> /etc/os-release && \
    # Create version file
    mkdir -p /etc/orb-os && \
    echo "Orb OS COSMIC - 2025-05-10 02:06:41" > /etc/orb-os/version && \
    # Update welcome message
    echo "Orb OS COSMIC (\l)" > /etc/issue && \
    echo "Orb OS COSMIC" > /etc/issue.net && \
    echo "Welcome to Orb OS with COSMIC desktop environment!" > /etc/motd && \
    # Copy branding to permanent location
    cp /etc/os-release /etc/orb-os-release

# Final systemd configuration
RUN systemctl set-default graphical.target
