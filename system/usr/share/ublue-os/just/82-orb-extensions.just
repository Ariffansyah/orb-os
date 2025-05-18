# justfile to preinstall and pre-enable GNOME extensions on uBlue

gnome-preinstall-extensions:
    # List of GNOME extension UUIDs and their EGO/extension IDs
    EXTENSIONS=(
      "openbar@neuromorph:6580"
      "vertical-workspaces@thibaultmol.github.com:5177"
      "Forge@jmmaranan.gmail.com:4481"
      "mediacontrols@cliffniff.github.com:4470"
      "dash-to-panel@jderose9.github.com:1160"
    )

    # Ensure gnome-shell-extension-installer is present
    if ! command -v gnome-shell-extension-installer >/dev/null; then
      echo "Installing gnome-shell-extension-installer..."
      sudo curl -o /usr/local/bin/gnome-shell-extension-installer \
        https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer
      sudo chmod +x /usr/local/bin/gnome-shell-extension-installer
    fi

    # Install and enable each extension
    for item in "${EXTENSIONS[@]}"; do
      IFS=":" read -r UUID EGO_ID <<< "$item"
      echo "Installing $UUID (ID: $EGO_ID)..."
      gnome-shell-extension-installer "$EGO_ID" --yes
      echo "Enabling $UUID..."
      gnome-extensions enable "$UUID" || echo "Will enable $UUID after next session if not enabled now."
    done

    echo "All extensions installed and enabled. Please restart GNOME Shell (Alt+F2, r, Enter) or log out and log back in if needed."
