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
