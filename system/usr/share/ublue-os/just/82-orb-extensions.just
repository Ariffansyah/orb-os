
set shell := ["bash", "-cu"]

EXT_DIR := "$HOME/.local/share/gnome-shell/extensions"

install:
    mkdir -p $EXT_DIR
    VERSION="$(gnome-shell --version | grep -o '[0-9]*\.[0-9]*')"

    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search=openbar@neuromorph" | jq ".extensions[] | select(.uuid==\"openbar@neuromorph\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf $EXT_DIR/openbar@neuromorph
    unzip -o /tmp/ext.zip -d $EXT_DIR/openbar@neuromorph
    rm /tmp/ext.zip
    gnome-extensions enable openbar@neuromorph || true

    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search=vertical-workspaces@thibaultmol.github.com" | jq ".extensions[] | select(.uuid==\"vertical-workspaces@thibaultmol.github.com\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf $EXT_DIR/vertical-workspaces@thibaultmol.github.com
    unzip -o /tmp/ext.zip -d $EXT_DIR/vertical-workspaces@thibaultmol.github.com
    rm /tmp/ext.zip
    gnome-extensions enable vertical-workspaces@thibaultmol.github.com || true

    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search=Forge@jmmaranan.gmail.com" | jq ".extensions[] | select(.uuid==\"Forge@jmmaranan.gmail.com\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf $EXT_DIR/Forge@jmmaranan.gmail.com
    unzip -o /tmp/ext.zip -d $EXT_DIR/Forge@jmmaranan.gmail.com
    rm /tmp/ext.zip
    gnome-extensions enable Forge@jmmaranan.gmail.com || true

    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search=mediacontrols@cliffniff.github.com" | jq ".extensions[] | select(.uuid==\"mediacontrols@cliffniff.github.com\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf $EXT_DIR/mediacontrols@cliffniff.github.com
    unzip -o /tmp/ext.zip -d $EXT_DIR/mediacontrols@cliffniff.github.com
    rm /tmp/ext.zip
    gnome-extensions enable mediacontrols@cliffniff.github.com || true

    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search=dash-to-panel@jderose9.github.com" | jq ".extensions[] | select(.uuid==\"dash-to-panel@jderose9.github.com\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf $EXT_DIR/dash-to-panel@jderose9.github.com
    unzip -o /tmp/ext.zip -d $EXT_DIR/dash-to-panel@jderose9.github.com
    rm /tmp/ext.zip
    gnome-extensions enable dash-to-panel@jderose9.github.com || true
