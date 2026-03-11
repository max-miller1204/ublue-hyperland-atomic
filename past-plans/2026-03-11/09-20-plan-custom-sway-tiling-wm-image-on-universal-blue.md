# Archived Plan

**Source:** `rustling-imagining-toucan.md`
**Session:** `22fbabeb-d54a-42e9-8246-89e048e2a6bc`
**Trigger:** `clear`
**Archived:** 2026-03-11 09:20:38

---

# Plan: Custom Sway Tiling WM Image on Universal Blue

## Context

The user wants to replace the current Bazzite (GNOME gaming-focused) base with a personal Sway tiling Wayland compositor setup on an immutable Fedora Atomic image. They have an NVIDIA Optimus laptop, want a heavy package set baked in, and need ISO generation for fresh installs. This is a personal daily-driver image, not a distributable template.

---

## Base Image Change

- **From:** `ghcr.io/ublue-os/bazzite:stable`
- **To:** `ghcr.io/ublue-os/base-nvidia:stable`
- Provides ublue conveniences + NVIDIA proprietary drivers without the gaming stack

---

## Package Manifest

### Compositor & Desktop
`sway` `waybar` `fuzzel` `mako` `swaylock` `swayidle` `swaybg` `polkit-gnome` `sddm` `kanshi` `brightnessctl`

### Wayland Utilities
`wl-clipboard` `grim` `slurp` `swappy` `wf-recorder`

### Terminal & Shell & File Manager
`alacritty` `zsh` `thunar`

### System Utilities
`htop` `btop` `neofetch` `fzf` `ripgrep` `bat` `eza` `tmux`

### Dev Tools
`git` `neovim` `gcc` `clang` `python3` `nodejs` `rust` `cargo` `podman` `distrobox`

### Networking, Audio, Power
`NetworkManager` `network-manager-applet` `blueman` `pavucontrol` `wireguard-tools` `playerctl` `tlp` `tlp-rdw`

### Fonts
`jetbrains-mono-fonts-all` (+ Nerd Font variant from GitHub releases or COPR)

### Packages needing COPR or manual install
- `yazi` - may need COPR, fallback to `ranger`
- JetBrains Mono Nerd Font - download from GitHub nerd-fonts releases
- SDDM dark theme - bundle in build_files or find COPR package

---

## Default Configs via /etc/skel

All configs baked into `/etc/skel/.config/` so new users get working defaults.

### Sway Config
- Mod key: Super (Mod4)
- Terminal: alacritty
- Launcher: fuzzel on `$mod+d`
- XWayland: enabled
- Autostart: waybar, mako, swaybg, swayidle, polkit-gnome, kanshi
- Touchpad: tap-to-click, natural scrolling
- Keybinds: standard tiling + screenshot (grim+slurp), volume/brightness keys, lock (`$mod+l`)

### Waybar Config
- Feature-rich: workspaces, clock, CPU, RAM, disk, network, bluetooth, PipeWire volume, battery, tray
- Media controls via playerctl
- Dark theme, JetBrains Mono Nerd Font

### Other Configs
- `alacritty.toml` - JetBrains Mono NF size 11, dark scheme
- `mako/config` - dark bg, 5s timeout, max 3 visible
- `kanshi/config` - laptop-only + docked profiles
- `.zshrc` - minimal (completion, history, aliases: ls->eza, cat->bat, grep->rg)

---

## NVIDIA Configuration

Set in `/etc/environment`:
```
WLR_NO_HARDWARE_CURSORS=1
WLR_RENDERER=vulkan
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
MOZ_ENABLE_WAYLAND=1
```

GPU mode: NVIDIA Prime Render Offload (default iGPU, `prime-run` for dGPU).

---

## SDDM

- Dark theme bundled in `build_files/sddm-theme/` and installed to `/usr/share/sddm/themes/`
- `/etc/sddm.conf` configured to use dark theme and default to Sway session
- Verify `sway` package creates `/usr/share/wayland-sessions/sway.desktop`

---

## Flatpak First-Boot

- Systemd oneshot service: `/etc/systemd/system/flatpak-first-boot.service`
- Script: `/usr/libexec/flatpak-first-boot.sh`
  1. Add Flathub repo
  2. Install `org.mozilla.firefox`
  3. Write stamp file `/var/lib/flatpak-first-boot-done`
  4. Disable self

---

## ISO Generation

- Create `disk_config/iso-sway.toml` - btrfs unencrypted, EFI + root
- Add Justfile recipes: `build-iso-sway`, `rebuild-iso-sway`

---

## CI/CD Updates

- Update `IMAGE_DESC` and `IMAGE_KEYWORDS` in `.github/workflows/build.yml`
- Update `image_name` default in Justfile

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `Containerfile` | Edit FROM line |
| `build_files/build.sh` | Rewrite - install all packages, copy configs, enable services |
| `build_files/sway-config` | Create |
| `build_files/waybar-config` | Create |
| `build_files/waybar-style.css` | Create |
| `build_files/alacritty.toml` | Create |
| `build_files/mako-config` | Create |
| `build_files/kanshi-config` | Create |
| `build_files/zshrc` | Create |
| `build_files/sddm.conf` | Create |
| `build_files/environment` | Create |
| `build_files/flatpak-first-boot.sh` | Create |
| `build_files/flatpak-first-boot.service` | Create |
| `disk_config/iso-sway.toml` | Create |
| `Justfile` | Edit - update image_name, add sway ISO recipes |
| `.github/workflows/build.yml` | Edit - update description/keywords |

---

## Verification

1. **Local build:** `podman build --tag sway-atomic:test .` - should complete without errors
2. **Inspect image:** `podman run --rm -it sway-atomic:test bash` - verify packages installed, configs in /etc/skel, services enabled
3. **ISO generation:** `just build-iso-sway` (requires Linux with podman + BIB)
4. **VM test:** `just run-vm-iso` to boot the ISO in a QEMU VM and verify SDDM + Sway launch

---

## Open Risks

1. **Nerd Font:** May need manual download from GitHub during build
2. **yazi:** COPR availability uncertain - fallback to ranger
3. **swappy:** Verify in Fedora repos, substitute `satty` if missing
4. **base-nvidia tag:** Verify exact tag format available on ghcr.io
5. **SDDM theme:** No standard dark theme in Fedora repos - will bundle manually
