install-extension UUID ZIP
  tmpdir=$(mktemp -d)
  unzip -o "$ZIP" -d "$tmpdir"
  uuid=$(jq -r .uuid "$tmpdir"/*/metadata.json || jq -r .uuid "$tmpdir"/metadata.json)
  if [ ! -n "$uuid" ]; then echo "Could not find UUID in $ZIP"; exit 1; fi
  rm -rf "$HOME/.local/share/gnome-shell/extensions/$uuid"
  mv "$tmpdir"/* "$HOME/.local/share/gnome-shell/extensions/$uuid" || mv "$tmpdir"/*/* "$HOME/.local/share/gnome-shell/extensions/$uuid"
  rm -rf "$tmpdir"
  gnome-extensions enable "$uuid" || true

install:
 mkdir -p "$HOME/.local/share/gnome-shell/extensions"

 # openbarneuromorph
 curl -L "https://extensions.gnome.org/extension-data/openbarneuromorph.v43.shell-extension.zip" -o /tmp/openbarneuromorph.zip
 just install-extension /tmp/openbarneuromorph.zip

 # dash-to-panel
 curl -L "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v66.shell-extension.zip" -o /tmp/dash-to-panel.zip
 just install-extension /tmp/dash-to-panel.zip

 # forge
 curl -L "https://extensions.gnome.org/extension-data/forgejmmaranan.com.v88.shell-extension.zip" -o /tmp/forge.zip
 just install-extension /tmp/forge.zip

 # vertical-workspaces
 curl -L "https://extensions.gnome.org/extension-data/vertical-workspacesG-dH.github.com.v85.shell-extension.zip" -o /tmp/vertical-workspaces.zip
 just install-extension /tmp/vertical-workspaces.zip

 # mediacontrols
 curl -L "https://extensions.gnome.org/extension-data/mediacontrolscliffniff.github.com.v38.shell-extension.zip" -o /tmp/mediacontrols.zip
 just install-extension /tmp/mediacontrols.zip
