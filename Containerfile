FROM ghcr.io/ublue-os/cosmic-atomic-main:42

ARG IMAGE_NAME="${IMAGE_NAME:-orb}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-cosmic}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-cosmic-atomic-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system /
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git \
    vim \
    zsh \
    starship \
    ghostty \
    ptyxis \
    tmux \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    gcc \
    make \
    ripgrep \
    fd-find \
    unzip \
    neovim \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    fastfetch \
    nodejs \
    npm \
    java-latest-openjdk \
    golang \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    python3 \
    python3-pip \
    python3-devel \
    || true && \
    /usr/libexec/build/clean.sh && \
    ostree container commit


### LINTING
## Verify final image and contents are correct.
COPY override /

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    systemctl enable podman.socket && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_pgdev-ghostty.repo && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_atim-starship.repo && \
    /usr/libexec/build/image-info && \
    /usr/libexec/build/clean.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit


RUN bootc container lint
