# Justfile to install and pre-enable GNOME Shell extensions on Fedora

set shell := ["bash", "-cu"]

# List of GNOME extension UUIDs to install and enable
EXTENSIONS := "openbar@neuromorph vertical-workspaces@thibaultmol.github.com Forge@jmmaranan.gmail.com mediacontrols@cliffniff.github.com dash-to-panel@jderose9.github.com"

# Directory where GNOME extensions are installed
EXT_DIR := "$HOME/.local/share/gnome-shell/extensions"

# Required dependencies: jq, curl, unzip, gnome-extensions
install-deps:
    sudo dnf install -y jq curl unzip gnome-extensions

# Download and install a GNOME extension by UUID (auto-resolves latest PK)
# Usage: just install-extension EXTENSION_UUID
install-extension uuid:
    mkdir -p {{EXT_DIR}}
    # Detect GNOME Shell version (major.minor)
    VERSION="$(gnome-shell --version | grep -o '[0-9]*\.[0-9]*')" && \
    # Find the extension's PK using the UUID
    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search={{uuid}}" | jq ".extensions[] | select(.uuid==\"{{uuid}}\") | .pk") && \
    # Get the download URL for the correct shell version
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$$PK&shell_version=$$VERSION" | jq -r '.download_url') && \
    # Download and unzip the extension
    curl -L "https://extensions.gnome.org$$DL_URL" -o /tmp/ext.zip && \
    rm -rf {{EXT_DIR}}/{{uuid}} && \
    unzip -o /tmp/ext.zip -d {{EXT_DIR}}/{{uuid}} && \
    rm /tmp/ext.zip
    # Enable the extension
    gnome-extensions enable {{uuid}} || true

# Install and enable all extensions listed in EXTENSIONS
install-all:
    for uuid in {{EXTENSIONS}}; do \
      just install-extension "$$uuid"; \
    done

# Main task: install dependencies and all extensions
install: install-deps install-all

# Usage:
# - Run: just install
# - Fedora only (uses dnf for dependencies)
# - No need to enter PK/UID manually; script resolves it automatically.
# - You can edit EXTENSIONS above to add or remove extensions.
