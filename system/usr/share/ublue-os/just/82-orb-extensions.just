set shell := ["bash", "-cu"]

toolbox-version := "2.6.2.41321"
toolbox-tar := "jetbrains-toolbox-{{toolbox-version}}.tar.gz"
toolbox-url := "https://download-cdn.jetbrains.com/toolbox/{{toolbox-tar}}"

install-toolbox:
    mkdir -p /usr/local/bin
    wget -O /tmp/{{toolbox-tar}} {{toolbox-url}}
    tar -xzf /tmp/{{toolbox-tar}} -C /tmp
    TOOLBOX_DIR=$$(find /tmp -maxdepth 1 -type d -name "jetbrains-toolbox-*") && \
    cp "$$TOOLBOX_DIR/jetbrains-toolbox" /usr/local/bin/jetbrains-toolbox
    chmod 755 /usr/local/bin/jetbrains-toolbox
    rm -rf /tmp/jetbrains-toolbox*

install:
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
  gnome-extensions enable dash-to-panel@jderose9.github.com || true
  gnome-extensions enable forge@jmmaranan.com || true
  gnome-extensions enable vertical-workspaces@G-dH.github.com || true
  gnome-extensions enable mediacontrols@cliffniff.github.com || true
