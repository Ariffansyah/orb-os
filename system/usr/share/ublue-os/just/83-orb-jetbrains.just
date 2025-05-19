# justfile for installing JetBrains Toolbox in a container or locally

toolbox-version := "2.6.2.41321"
toolbox-tar := "jetbrains-toolbox-{{toolbox-version}}.tar.gz"
toolbox-url := "https://download.jetbrains.com/toolbox/jetbrains-toolbox-{{toolbox-version}}.tar.gz"

install-toolbox:
    # Download JetBrains Toolbox tar.gz
    wget -O /tmp/{{toolbox-tar}} {{toolbox-url}}
    # Extract
    tar -xzf /tmp/{{toolbox-tar}} -C /tmp
    # Find extracted directory
    TOOLBOX_DIR=$$(find /tmp -maxdepth 1 -type d -name "jetbrains-toolbox-*") && \
    mkdir -p /usr/local/bin
    # Copy binary
    cp "$$TOOLBOX_DIR/jetbrains-toolbox" /usr/local/bin/jetbrains-toolbox
    chmod 755 /usr/local/bin/jetbrains-toolbox
    # Clean up
    rm -rf /tmp/jetbrains-toolbox*

# Usage:
# just install-toolbox
