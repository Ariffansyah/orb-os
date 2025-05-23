set shell := ["bash", "-cu"]

install:
  curl -L "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v66.shell-extension.zip" -o /tmp/dash-to-panel.zip
  curl -L "https://extensions.gnome.org/extension-data/forgejmmaranan.com.v88.shell-extension.zip" -o /tmp/forge.zip
  curl -L "https://extensions.gnome.org/extension-data/vertical-workspacesG-dH.github.com.v85.shell-extension.zip" -o /tmp/vertical-workspaces.zip
  curl -L "https://extensions.gnome.org/extension-data/mediacontrolscliffniff.github.com.v38.shell-extension.zip" -o /tmp/mediacontrols.zip
  gnome-extensions install --force /tmp/dash-to-panel.zip || true
  gnome-extensions install --force /tmp/forge.zip || true
  gnome-extensions install --force /tmp/vertical-workspaces.zip || true
  gnome-extensions install --force /tmp/mediacontrols.zip || true
  echo "Installed. please reboot, then run: ujust enable"

enable:
  gnome-extensions enable dash-to-panel@jderose9.github.com || true
  gnome-extensions enable forge@jmmaranan.com || true
  gnome-extensions enable vertical-workspaces@G-dH.github.com || true
  gnome-extensions enable mediacontrols@cliffniff.github.com || true
