#!/bin/bash
set -ouex pipefail

###############################################################################
# NVIDIA driver installation via ublue akmods
# Adapted from https://github.com/ublue-os/main/blob/main/build_files/nvidia-install.sh
###############################################################################

FRELEASE="$(rpm -E %fedora)"
AKMODNV_PATH="/tmp/akmods-nv-rpms"

# Install dnf5-plugins for config-manager subcommand
dnf5 install -y 'dnf5-command(config-manager)'

# Show what's available for debugging
find "${AKMODNV_PATH}"/

# Disable rpmfusion and cisco repos if present (avoid conflicts with negativo17)
if dnf5 repolist --all 2>/dev/null | grep -q rpmfusion; then
    dnf5 config-manager setopt "rpmfusion*".enabled=0
fi
dnf5 config-manager setopt fedora-cisco-openh264.enabled=0 || true

# Install ublue NVIDIA addons (provides repo configs and signing keys)
dnf5 install -y "${AKMODNV_PATH}"/ublue-os/ublue-os-nvidia-addons-*.rpm

# Install 32-bit mesa libraries (needed for some apps/games)
dnf5 install -y \
    mesa-dri-drivers.i686 \
    mesa-filesystem.i686 \
    mesa-libEGL.i686 \
    mesa-libGL.i686 \
    mesa-libgbm.i686 \
    mesa-va-drivers.i686 \
    mesa-vulkan-drivers.i686

# Enable NVIDIA repos provided by ublue-os-nvidia-addons
dnf5 config-manager setopt fedora-nvidia.enabled=1 nvidia-container-toolkit.enabled=1

# Disable multimedia repo temporarily to avoid conflicts
if dnf5 repolist --enabled | grep -q "fedora-multimedia"; then
    dnf5 config-manager setopt fedora-multimedia.enabled=0
    RESTORE_MULTIMEDIA=1
fi

# Source NVIDIA version variables from akmods
source "${AKMODNV_PATH}"/kmods/nvidia-vars

# Install NVIDIA driver stack + kernel module
dnf5 install -y \
    libnvidia-fbc \
    libnvidia-ml.i686 \
    libva-nvidia-driver \
    nvidia-driver \
    nvidia-driver-cuda \
    nvidia-driver-cuda-libs.i686 \
    nvidia-driver-libs.i686 \
    nvidia-settings \
    nvidia-container-toolkit \
    "${AKMODNV_PATH}"/kmods/kmod-nvidia-"${KERNEL_VERSION}"-"${NVIDIA_AKMOD_VERSION}"."${DIST_ARCH}".rpm

# Verify kmod and driver versions match
KMOD_VERSION="$(rpm -q --queryformat '%{VERSION}' kmod-nvidia)"
DRIVER_VERSION="$(rpm -q --queryformat '%{VERSION}' nvidia-driver)"
if [ "$KMOD_VERSION" != "$DRIVER_VERSION" ]; then
    echo "ERROR: kmod-nvidia version ($KMOD_VERSION) does not match nvidia-driver version ($DRIVER_VERSION)"
    exit 1
fi

# Disable NVIDIA repos (don't leave them enabled in the final image)
dnf5 config-manager setopt fedora-nvidia.enabled=0 fedora-nvidia-lts.enabled=0 nvidia-container-toolkit.enabled=0

# Restore multimedia repo if it was enabled
if [ "${RESTORE_MULTIMEDIA:-0}" = "1" ]; then
    dnf5 config-manager setopt fedora-multimedia.enabled=1
fi

# Enable NVIDIA container toolkit CDI service
systemctl enable ublue-nvctk-cdi.service

# Install SELinux policy for NVIDIA containers
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp

# Initramfs fixes for NVIDIA
if [ -f /etc/modprobe.d/nvidia-modeset.conf ]; then
    cp /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf
fi
# Force-load NVIDIA driver to prevent black screen on boot
if [ -f /usr/lib/dracut/dracut.conf.d/99-nvidia.conf ]; then
    sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
    # Also pre-load iGPU drivers for hardware acceleration in browsers
    sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
fi
