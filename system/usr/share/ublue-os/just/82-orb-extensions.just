set shell := ["bash", "-cu"]

EXTENSIONS := "openbar@neuromorph vertical-workspaces@thibaultmol.github.com Forge@jmmaranan.gmail.com mediacontrols@cliffniff.github.com dash-to-panel@jderose9.github.com"

EXT_DIR := "$HOME/.local/share/gnome-shell/extensions"

install-extension uuid:
    mkdir -p {{EXT_DIR}}
    VERSION="$(gnome-shell --version | grep -o '[0-9]*\.[0-9]*')"
    PK=$(curl -s "https://extensions.gnome.org/extension-query/?search={{uuid}}" \
      | jq ".extensions[] | select(.uuid==\"{{uuid}}\") | .pk")
    DL_URL=$(curl -s "https://extensions.gnome.org/extension-info/?pk=$PK&shell_version=$VERSION" \
      | jq -r '.download_url')
    curl -L "https://extensions.gnome.org$DL_URL" -o /tmp/ext.zip
    rm -rf {{EXT_DIR}}/{{uuid}}
    unzip -o /tmp/ext.zip -d {{EXT_DIR}}/{{uuid}}
    rm /tmp/ext.zip
    gnome-extensions enable {{uuid}} || true

install-all:
    for uuid in {{EXTENSIONS}}; do
        just install-extension "$$uuid";
    done

install: install-all
