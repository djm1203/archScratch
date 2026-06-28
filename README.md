# archScratch

Personal Arch Linux dotfiles — Hyprland desktop setup. Clone and run one command to get a fully configured system.

## Stack

| Component       | Package                        |
|-----------------|-------------------------------|
| Compositor      | Hyprland                      |
| Display Manager | greetd + agreety              |
| Bar             | Waybar                        |
| App Launcher    | Wofi                          |
| Notifications   | Mako                          |
| Wallpaper       | swww + Waypaper               |
| Lock / Idle     | Hyprlock + Hypridle           |
| File Manager    | Dolphin                       |
| Terminal        | Foot (default) · Kitty (for a background image) |
| Shell           | Zsh + oh-my-zsh + Powerlevel10k |
| Editors         | Neovim (LazyVim) · VS Code    |
| Dev tooling     | node, go, rust, ruby + rails, docker, lazygit, fzf, ripgrep, fd, bat, eza, jq, tmux, gdb, cmake |
| Theme           | Tokyo Night / Catppuccin Mocha (mauve accent) |
| Icons           | Papirus (breeze-dark)         |
| Fonts           | JetBrains Mono Nerd, Inter    |

## Prerequisites

- Fresh Arch Linux install (base + base-devel + git + sudo + a user account)
- Internet connection
- `sudo` access

## Install

```bash
git clone git@github.com:djm1203/archScratch.git
cd archScratch
./install.sh
```

The script will:
1. Install all pacman packages
2. Install AUR packages via `yay`
3. Prompt for CPU microcode (Intel/AMD)
4. Prompt for NVIDIA GPU drivers + optional ASUS G14 tools
5. Set up Zsh + oh-my-zsh + Powerlevel10k + plugins
6. Build `waybar-module-pomodoro` from source (Rust)
7. Optionally install Claude Code CLI
8. Symlink all dotfiles into `~/.config/` (backs up existing files)
9. Configure greetd
10. Enable systemd services
11. Prompt to reboot

> The installer is **resilient**: it does not abort on the first error. Each step is
> tracked and a pass/fail summary is printed at the end, and a full log is written to
> `~/archscratch-install-<timestamp>.log`. A single bad package no longer fails the batch.

## Updating

After the first install, pull changes and apply them with:

```bash
cd archScratch && ./install.sh --upgrade
```

This `git pull`s (auto-stashing any live edits to your symlinked configs), prints the
commits it pulled (your "release notes"), installs any newly-listed packages, redeploys
configs + services, and live-reloads Hyprland/Waybar. It skips the one-time setup
(hardware/microcode/NVIDIA prompts, git accounts, shell change). Because configs are
symlinked into the repo, a plain `git pull` already updates dotfiles instantly —
`--upgrade` is for picking up new packages, services, and files.

## After Install

- Run `p10k configure` on first zsh login to set up your prompt
- Run `nwg-displays` to configure your monitor layout (resolution, scale, position)
- `Super+W` opens the wallpaper picker — sample `moon.png` is in `~/Pictures/Wallpapers/`
- **Wallpapers auto-rotate** every 15 min via a systemd user timer (`wallpaper-rotate.timer`).
  Drop more images into `Wallpapers/` (they deploy to `~/Pictures/Wallpapers/`).
- **Terminal background image:** open Kitty with `Super+Shift+T` and place your image at
  `~/.config/kitty/bg.png` (i.e. `Configs/kitty/bg.png` in the repo). Foot stays the default
  terminal and uses transparency over the wallpaper instead.

## Recoloring (changing the accent)

The accent color (currently mauve `#cba6f7`) is centralized. To recolor the whole desktop,
change it in these spots and reload:

- `Configs/hypr/colors.conf` — `$accent` (window borders, lock screen)
- `Configs/waybar/style.css` — `@define-color accent` (top of file)
- `Configs/wofi/style.css` — `@define-color accent`
- `Configs/mako/config` — `border-color`
- `Configs/kitty/kitty.conf` / `Configs/foot/foot.ini` — palette (optional)

## Keybindings

| Key                  | Action                  |
|----------------------|-------------------------|
| `Super+T`            | Terminal (foot)         |
| `Super+Shift+T`      | Terminal (kitty, bg image) |
| `Super+B`            | Browser (Firefox)       |
| `Super+E`            | File manager (Dolphin)  |
| `Super+R` / `A`      | App launcher (Wofi)     |
| `Super+L`            | Lock screen             |
| `Super+Escape`       | Power menu              |
| `Super+W`            | Wallpaper picker        |
| `Super+C`            | Clipboard history (cliphist) |
| `Print`              | Screenshot full → file + clipboard |
| `Shift+Print`        | Screenshot region → file + clipboard |
| `Super+Shift+Print`  | Screenshot region → swappy (annotate) |
| `Super+V`            | Toggle floating         |
| `Super+Shift+C`      | Toggle caffeine (no sleep) |
| `Super+[1-0]`        | Switch workspace        |
| `Super+Shift+[1-0]`  | Move window to workspace |
| `Super+S`            | Special workspace       |
| `Super+Z` (drag)     | Move window             |
| `Super+X` (drag)     | Resize window           |

## Structure

```
archScratch/
├── install.sh           # entry point
├── Scripts/
│   ├── pkg_pacman.lst   # pacman packages
│   ├── pkg_aur.lst      # AUR packages (VS Code, spotify, …)
│   ├── svc_enable.lst   # systemd services
│   ├── global_fn.sh     # shared helpers (incl. resilient pac_install)
│   ├── pkg_install.sh
│   ├── restore_cfg.sh   # deploys dotfiles (symlinks)
│   ├── restore_svc.sh
│   ├── install_zsh.sh
│   ├── install_pomodoro.sh
│   ├── install_git_accounts.sh
│   ├── install_claude.sh
│   ├── install_plymouth.sh # opt-in boot splash (Catppuccin)
│   └── emergency_pkg.sh # resilient recovery if pkg_install fails
├── Configs/             # all ~/.config/ files
│   ├── hypr/colors.conf # central accent palette
│   ├── kitty/           # terminal w/ background image
│   └── systemd/user/    # wallpaper-rotate.{service,timer}
├── local-bin/           # scripts → ~/.local/bin/ (incl. wallpaper-rotate)
├── home/                # home dotfiles (.zshrc)
├── system/              # system config (greetd)
└── Wallpapers/          # wallpaper set (auto-rotated)
```

## Extending

Adding your own apps, configs, wallpapers, services, or keybinds is a quick edit — see
[docs/EXTENDING.md](docs/EXTENDING.md) for the how-to.

## Notes

- `monitors.conf` defaults to `monitor=,preferred,auto,1` (auto-detect all displays). Use `nwg-displays` to generate a proper config after logging in.
- Existing config files are backed up to `~/.config-backup-<timestamp>/` before being replaced.
- `waybar-module-pomodoro` is built from source: [Andeskjerf/waybar-module-pomodoro](https://github.com/Andeskjerf/waybar-module-pomodoro)
