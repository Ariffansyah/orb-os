# Justfile to install and pre-enable GNOME Shell extensions

set shell := ["bash", "-cu"]

# List of GNOME extension UUIDs to install and enable
EXTENSIONS := "openbar@neuromorph vertical-workspaces@thibaultmol.github.com Forge@jmmaranan.gmail.com mediacontrols@cliffniff.github.com dash-to-panel@jderose9.github.com"

# Directory where GNOME extensions are installed
EXT_DIR := "$HOME/.local/share/gnome-shell/extensions"

# URL for GNOME Extensions website
EXT_URL := "https://extensions.gnome.org/extension-query/"

# Required dependencies: jq, curl, unzip
install-deps:
    sudo apt-get update
    sudo apt-get install -y jq curl unzip

# Download and install a GNOME extension by UUID
# Usage: just install-extension EXTENSION_UUID
install-extension uuid:
    mkdir -p {{EXT_DIR}}
    # Get GNOME Shell version
    VERSION="$(gnome-shell --version | grep -o '[0-9]*\\.[0-9]*')" && \
    # Get extension metadata and download URL
    DATA="$(curl -s "{{EXT_URL}}?search={{uuid}}")" && \
    PK=$(echo $$DATA | jq '.extensions[] | select(.uuid=="{{uuid}}") | .pk') && \
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$$PK&shell_version=$$VERSION" | jq -r '.download_url') && \
    curl -L "https://extensions.gnome.org$$DL_URL" -o /tmp/ext.zip && \
    rm -rf {{EXT_DIR}}/{{uuid}} && \
    unzip -o /tmp/ext.zip -d {{EXT_DIR}}/{{uuid}} && \
    rm /tmp/ext.zip
    # Pre-enable the extension
    gnome-extensions enable {{uuid}} || true

# Install and enable all extensions listed in EXTENSIONS
install-all:
    for uuid in {{EXTENSIONS}}; do \
      just install-extension "$$uuid"; \
    done

# Main task: install dependencies and all extensions
install: install-deps install-all

# Example usage:
# 1. Run: just install
#
# Requirements:
# - just
# - jq, curl, unzip (install-deps task will install them on Debian/Ubuntu)
# - gnome-shell, gnome-extensions CLI
