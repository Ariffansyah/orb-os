set shell := ["bash", "-cu"]

install:
 mkdir -p "$HOME/.local/share/gnome-shell/extensions"

 # openbar@neuromorph
 curl -L "https://extensions.gnome.org/download/extension-files/6099/openbarneuromorph@neuromorph.github.com.v41.shell-extension.zip" -o /tmp/ext.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
 unzip -o /tmp/ext.zip -d "$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
 rm /tmp/ext.zip
 gnome-extensions enable openbar@neuromorph || true

 # vertical-workspaces@thibaultmol.github.com
 curl -L "https://extensions.gnome.org/download/extension-files/4481/vertical-workspaces@thibaultmol.github.com.v37.shell-extension.zip" -o /tmp/ext.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/vertical-workspaces@thibaultmol.github.com"
 unzip -o /tmp/ext.zip -d "$HOME/.local/share/gnome-shell/extensions/vertical-workspaces@thibaultmol.github.com"
 rm /tmp/ext.zip
 gnome-extensions enable vertical-workspaces@thibaultmol.github.com || true

 # Forge@jmmaranan.gmail.com
 curl -L "https://extensions.gnome.org/download/extension-files/4424/forge@jmmaranan.gmail.com.v9.shell-extension.zip" -o /tmp/ext.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/Forge@jmmaranan.gmail.com"
 unzip -o /tmp/ext.zip -d "$HOME/.local/share/gnome-shell/extensions/Forge@jmmaranan.gmail.com"
 rm /tmp/ext.zip
 gnome-extensions enable Forge@jmmaranan.gmail.com || true

 # mediacontrols@cliffniff.github.com
 curl -L "https://extensions.gnome.org/download/extension-files/4477/mediacontrols@cliffniff.github.com.v22.shell-extension.zip" -o /tmp/ext.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/mediacontrols@cliffniff.github.com"
 unzip -o /tmp/ext.zip -d "$HOME/.local/share/gnome-shell/extensions/mediacontrols@cliffniff.github.com"
 rm /tmp/ext.zip
 gnome-extensions enable mediacontrols@cliffniff.github.com || true

 # dash-to-panel@jderose9.github.com
 curl -L "https://extensions.gnome.org/download/extension-files/1160/dash-to-panel@jderose9.github.com.v56.shell-extension.zip" -o /tmp/ext.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
 unzip -o /tmp/ext.zip -d "$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
 rm /tmp/ext.zip
 gnome-extensions enable dash-to-panel@jderose9.github.com || true
