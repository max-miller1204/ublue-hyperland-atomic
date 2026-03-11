# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# NVIDIA akmods — pre-built kernel modules from Universal Blue
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG IMAGE_REGISTRY=ghcr.io/ublue-os
FROM ${IMAGE_REGISTRY}/akmods:main-${FEDORA_MAJOR_VERSION} AS akmods
FROM ${IMAGE_REGISTRY}/akmods-nvidia-open:main-${FEDORA_MAJOR_VERSION} AS akmods_nvidia

# Base Image — plain Fedora bootc (no ublue signature issues)
FROM quay.io/fedora/fedora-bootc:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"

### MODIFICATIONS
## Install packages, NVIDIA drivers, deploy configs, enable services

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=akmods,src=/rpms/ublue-os,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    /ctx/build.sh && \
    /ctx/nvidia-install.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
