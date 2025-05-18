set shell := ["bash", "-cu"]

install:
 mkdir -p "$HOME/.local/share/gnome-shell/extensions"

 # openbarneuromorph
 curl -L "https://extensions.gnome.org/extension-data/openbarneuromorph.v43.shell-extension.zip" -o /tmp/openbarneuromorph.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/openbarneuromorph"
 unzip -o /tmp/openbarneuromorph.zip -d "$HOME/.local/share/gnome-shell/extensions/openbarneuromorph"
 rm /tmp/openbarneuromorph.zip
 gnome-extensions enable openbarneuromorph || true

 # dash-to-panel
 curl -L "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v66.shell-extension.zip" -o /tmp/dash-to-panel.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/dash-to-paneljderose9.github.com"
 unzip -o /tmp/dash-to-panel.zip -d "$HOME/.local/share/gnome-shell/extensions/dash-to-paneljderose9.github.com"
 rm /tmp/dash-to-panel.zip
 gnome-extensions enable dash-to-paneljderose9.github.com || true

 # forge
 curl -L "https://extensions.gnome.org/extension-data/forgejmmaranan.com.v88.shell-extension.zip" -o /tmp/forge.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/forgejmmaranan.com"
 unzip -o /tmp/forge.zip -d "$HOME/.local/share/gnome-shell/extensions/forgejmmaranan.com"
 rm /tmp/forge.zip
 gnome-extensions enable forgejmmaranan.com || true

 # vertical-workspaces
 curl -L "https://extensions.gnome.org/extension-data/vertical-workspacesG-dH.github.com.v85.shell-extension.zip" -o /tmp/vertical-workspaces.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/vertical-workspacesG-dH.github.com"
 unzip -o /tmp/vertical-workspaces.zip -d "$HOME/.local/share/gnome-shell/extensions/vertical-workspacesG-dH.github.com"
 rm /tmp/vertical-workspaces.zip
 gnome-extensions enable vertical-workspacesG-dH.github.com || true

 # mediacontrols
 curl -L "https://extensions.gnome.org/extension-data/mediacontrolscliffniff.github.com.v38.shell-extension.zip" -o /tmp/mediacontrols.zip
 rm -rf "$HOME/.local/share/gnome-shell/extensions/mediacontrolscliffniff.github.com"
 unzip -o /tmp/mediacontrols.zip -d "$HOME/.local/share/gnome-shell/extensions/mediacontrolscliffniff.github.com"
 rm /tmp/mediacontrols.zip
 gnome-extensions enable mediacontrolscliffniff.github.com || true
