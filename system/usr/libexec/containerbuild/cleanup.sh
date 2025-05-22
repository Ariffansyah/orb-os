#!/usr/bin/bash

## This script is used to clean up the system by removing temporary files and directories.
set -eoux pipefail
shopt -s extglob

rm -rf /tmp/* || true
rm -rf /var/!(cache)
rm -rf /var/cache/!(rpm-ostree)
