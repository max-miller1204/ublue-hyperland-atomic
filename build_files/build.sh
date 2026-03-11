#!/bin/bash
set -ouex pipefail

###############################################################################
# Sway Tiling WM — build script for Universal Blue custom image
###############################################################################

### Install ublue common akmods (base support packages)
dnf5 install -y /tmp/akmods-rpms/ublue-os-akmods*.rpm || true

### Install packages

# Compositor & Desktop
dnf5 install -y \
    sway \
    waybar \
    fuzzel \
    mako \
    swaylock \
    swayidle \
    swaybg \
    polkit-gnome \
    sddm \
    kanshi \
    brightnessctl

# Wayland Utilities
dnf5 install -y \
    wl-clipboard \
    grim \
    slurp \
    swappy \
    wf-recorder

# Terminal & Shell & File Manager
dnf5 install -y \
    alacritty \
    zsh \
    thunar

# System Utilities
dnf5 install -y \
    htop \
    btop \
    neofetch \
    fzf \
    ripgrep \
    bat \
    eza \
    tmux

# Dev Tools
dnf5 install -y \
    git \
    neovim \
    gcc \
    clang \
    python3 \
    nodejs \
    rust \
    cargo \
    podman \
    distrobox

# Networking, Audio, Power
dnf5 install -y \
    NetworkManager \
    network-manager-applet \
    blueman \
    pavucontrol \
    wireguard-tools \
    playerctl \
    tlp \
    tlp-rdw

# Fonts
dnf5 install -y \
    jetbrains-mono-fonts-all

# Try to install yazi; fall back to ranger if unavailable
dnf5 install -y yazi || dnf5 install -y ranger

###############################################################################
# Download JetBrainsMono Nerd Font
###############################################################################
NERD_FONT_VERSION="v3.3.0"
NERD_FONT_DIR="/usr/share/fonts/jetbrains-mono-nerd"
mkdir -p "$NERD_FONT_DIR"
curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz" \
    -o /tmp/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C "$NERD_FONT_DIR"
rm -f /tmp/JetBrainsMono.tar.xz
fc-cache -f "$NERD_FONT_DIR"

###############################################################################
# Deploy config files to /etc/skel (default user config)
###############################################################################

# Sway
mkdir -p /etc/skel/.config/sway
cp /ctx/sway-config /etc/skel/.config/sway/config

# Waybar
mkdir -p /etc/skel/.config/waybar
cp /ctx/waybar-config /etc/skel/.config/waybar/config
cp /ctx/waybar-style.css /etc/skel/.config/waybar/style.css

# Alacritty
mkdir -p /etc/skel/.config/alacritty
cp /ctx/alacritty.toml /etc/skel/.config/alacritty/alacritty.toml

# Mako
mkdir -p /etc/skel/.config/mako
cp /ctx/mako-config /etc/skel/.config/mako/config

# Kanshi
mkdir -p /etc/skel/.config/kanshi
cp /ctx/kanshi-config /etc/skel/.config/kanshi/config

# Zsh
cp /ctx/zshrc /etc/skel/.zshrc

###############################################################################
# NVIDIA environment variables
###############################################################################
cp /ctx/environment /etc/environment

###############################################################################
# SDDM configuration & theme
###############################################################################
cp /ctx/sddm.conf /etc/sddm.conf
mkdir -p /usr/share/sddm/themes/sway-dark
cp -r /ctx/sddm-theme/* /usr/share/sddm/themes/sway-dark/

###############################################################################
# Flatpak first-boot service
###############################################################################
cp /ctx/flatpak-first-boot.sh /usr/libexec/flatpak-first-boot.sh
chmod +x /usr/libexec/flatpak-first-boot.sh
cp /ctx/flatpak-first-boot.service /etc/systemd/system/flatpak-first-boot.service

###############################################################################
# Enable system services
###############################################################################
systemctl enable podman.socket
systemctl enable sddm.service
systemctl enable tlp.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable flatpak-first-boot.service
