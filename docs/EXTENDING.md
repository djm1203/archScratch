---
title: "EXTENDING"
project: archScratch
classification: high
created: 2026-06-27
updated: 2026-06-27
product_id: archScratch
project_id: archScratch
file_kind: Guide
author: Derek Martinez
---

# Extending archScratch

How to add your own stuff to this setup. Because configs are **symlinked** into the repo,
most changes are live the moment you edit/pull — re-run `./install.sh --upgrade` to pick up
new packages, services, or files.

## Quick reference

| To add… | Do this |
|---------|---------|
| **An app / CLI tool** | Add the package name to `Scripts/pkg_pacman.lst` (official repos) or `Scripts/pkg_aur.lst` (AUR). |
| **A config for an app** | Drop the folder in `Configs/<app>/`, then add `<app>` to the loop in `Scripts/restore_cfg.sh` → `deploy_configs()`. |
| **A wallpaper** | Drop a `.png/.jpg/.jpeg/.webp` into `Wallpapers/`. Auto-deployed + rotated. |
| **A systemd service** | Add the unit name to `Scripts/svc_enable.lst` (system units). For **user** units, add the file to `Configs/systemd/user/`. |
| **A keybind / autostart** | Edit `Configs/hypr/hyprland.conf` (`bind = …` or `exec-once = …`). |
| **A `~/.local/bin` script** | Drop an executable in `local-bin/` (then `git update-index --chmod=+x` it). |
| **Recolor the accent** | Change `$accent` in `Configs/hypr/colors.conf` and `@define-color accent` in `Configs/waybar/style.css` + `Configs/wofi/style.css` (and `Configs/mako/config`). See README "Recoloring". |

## Details & gotchas

### Adding an app
Just a list edit:
```
# Scripts/pkg_pacman.lst  (one package per line; # for comments)
my-new-app
```
Use `pkg_aur.lst` for AUR packages. The installer is resilient — a bad/renamed package name
warns and is skipped rather than failing the whole run. Re-run `./install.sh --upgrade`.

### Adding a config
1. Put the app's config under `Configs/<app>/` (matching what it expects in `~/.config/<app>`).
2. Add `<app>` to the directory list in `Scripts/restore_cfg.sh` (`deploy_configs()`), e.g.:
   ```bash
   for d in hypr waybar foot kitty ... <app>; do
   ```
3. `./install.sh --upgrade` symlinks it into `~/.config/<app>` (backing up anything pre-existing).

> The deploy is **non-destructive**: existing real files are moved to
> `~/.config-backup-<timestamp>/` before the symlink is created.

### Adding a service
- **System unit** (needs root): add the name to `Scripts/svc_enable.lst`. It's enabled with
  `systemctl enable --now`; failures warn rather than abort.
- **User unit**: drop the `.service`/`.timer` into `Configs/systemd/user/` (see
  `wallpaper-rotate.*` as a template). `restore_cfg.sh` symlinks and `daemon-reload`s them.

### Adding a local-bin script
Put it in `local-bin/`, keep it executable in git:
```bash
git add local-bin/my-script && git update-index --chmod=+x local-bin/my-script
```
It's symlinked into `~/.local/bin` (already on PATH via `.zshrc`).

### Hardware-specific bits
ASUS/NVIDIA/microcode and the g14 kernel/bootloader live in `Scripts/pkg_install.sh` behind
prompts — edit there, not the lists.

## After any change
- Lint: `shellcheck install.sh Scripts/*.sh` and `bash -n` (CI runs shellcheck on push).
- Test risky changes (packages, boot config, services) in a **disposable Arch VM** first.
- Apply on a real machine with `./install.sh --upgrade` (or a plain `git pull` for pure config tweaks).
