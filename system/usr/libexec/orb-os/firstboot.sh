#!/bin/bash

# Set the correct origin for the current deployment
CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].id')
if [ -n "$CURRENT_DEPLOYMENT" ]; then
    rpm-ostree origin -b 0 referrer set ostree-unverified-registry:ghcr.io/ariffansyah/orb-os:latest
    echo "Origin reference updated to ostree-unverified-registry:ghcr.io/ariffansyah/orb-os:latest"
else
    echo "Failed to determine current deployment"
    exit 1
fi
