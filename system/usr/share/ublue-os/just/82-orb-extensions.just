set shell := ["bash", "-cu"]

install:
  # openbarneuromorph
  curl -L "https://extensions.gnome.org/extension-data/openbarneuromorph.v43.shell-extension.zip" -o /tmp/openbarneuromorph.zip
  gnome-extensions install --force /tmp/openbarneuromorph.zip || true

  # dash-to-panel
  curl -L "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v66.shell-extension.zip" -o /tmp/dash-to-panel.zip
  gnome-extensions install --force /tmp/dash-to-panel.zip || true

  # forge
  curl -L "https://extensions.gnome.org/extension-data/forgejmmaranan.com.v88.shell-extension.zip" -o /tmp/forge.zip
  gnome-extensions install --force /tmp/forge.zip || true

  # vertical-workspaces
  curl -L "https://extensions.gnome.org/extension-data/vertical-workspacesG-dH.github.com.v85.shell-extension.zip" -o /tmp/vertical-workspaces.zip
  gnome-extensions install --force /tmp/vertical-workspaces.zip || true

  # mediacontrols
  curl -L "https://extensions.gnome.org/extension-data/mediacontrolscliffniff.github.com.v38.shell-extension.zip" -o /tmp/mediacontrols.zip
  gnome-extensions install --force /tmp/mediacontrols.zip || true
  echo "Installed. please reboot, then run: ujust enable"

enable:
  gnome-extensions enable openbar@neuromorph || true
  gnome-extensions enable dash-to-panel@jderose9.github.com || true
  gnome-extensions enable forge@jmmaranan.com || true
  gnome-extensions enable vertical-workspaces@G-dH.github.com || true
  gnome-extensions enable mediacontrols@cliffniff.github.com || true
