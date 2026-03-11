#!/bin/bash
# Flatpak first-boot setup — runs once on initial boot

set -euo pipefail

STAMP=/var/lib/flatpak-first-boot-done

if [ -f "$STAMP" ]; then
    echo "First boot setup already completed."
    exit 0
fi

echo "Running first-boot Flatpak setup..."

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install default Flatpak apps
flatpak install -y --noninteractive flathub org.mozilla.firefox

# Mark as done
touch "$STAMP"

# Disable this service so it doesn't run again
systemctl disable flatpak-first-boot.service

echo "First-boot Flatpak setup complete."
