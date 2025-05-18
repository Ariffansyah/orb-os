# Download and install GNOME extensions to the current user's extension directory
install-extensions:
    set -e
    EXT_DIR="${HOME}/.local/share/gnome-shell/extensions"
    GNOME_VER=45
    mkdir -p "$$EXT_DIR"
    declare -A EXT_IDS=(
      [openbar@neuromorph]=6580
      [vertical-workspaces@thibaultmol.github.com]=5177
      [Forge@jmmaranan.gmail.com]=4481
      [mediacontrols@cliffniff.github.com]=4470
      [dash-to-panel@jderose9.github.com]=1160
    )
    for UUID in "$${!EXT_IDS[@]}"; do \
      ID=$${EXT_IDS[$$UUID]}; \
      ZIP_PATH=$$(curl -s "https://extensions.gnome.org/extension-info/?pk=$$ID&shell_version=$$GNOME_VER" | grep -oP '"download_url":\s*"\K[^"]+'); \
      if [ -z "$$ZIP_PATH" ]; then echo "Failed to find ZIP for $$UUID (ID $$ID)"; exit 1; fi; \
      wget -O "/tmp/$$ID.zip" "https://extensions.gnome.org$$ZIP_PATH"; \
      unzip -o "/tmp/$$ID.zip" -d "$$EXT_DIR/$$UUID"; \
    done; \
    rm /tmp/*.zip

# Enable the GNOME extensions for the user
enable-extensions:
    gnome-extensions enable dash-to-panel@jderose9.github.com || true
    gnome-extensions enable mediacontrols@cliffniff.github.com || true
    gnome-extensions enable openbar@neuromorph || true
    gnome-extensions enable Forge@jmmaranan.gmail.com || true
    gnome-extensions enable vertical-workspaces@thibaultmol.github.com || true

# All-in-one command: install extensions and enable them
setup: install-extensions enable-extensions
