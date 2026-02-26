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
| Terminal        | Foot                          |
| Shell           | Zsh + oh-my-zsh + Powerlevel10k |
| Editor          | Neovim (LazyVim)              |
| Theme           | Tokyo Night / Catppuccin Mocha |
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

## After Install

- Run `p10k configure` on first zsh login to set up your prompt
- Run `nwg-displays` to configure your monitor layout (resolution, scale, position)
- `Super+W` opens the wallpaper picker — sample `moon.png` is included in `~/Pictures/Wallpapers/`

## Keybindings

| Key                  | Action                  |
|----------------------|-------------------------|
| `Super+T`            | Terminal (foot)         |
| `Super+B`            | Browser (Firefox)       |
| `Super+E`            | File manager (Dolphin)  |
| `Super+R` / `A`      | App launcher (Wofi)     |
| `Super+L`            | Lock screen             |
| `Super+Escape`       | Power menu              |
| `Super+W`            | Wallpaper picker        |
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
│   ├── pkg_aur.lst      # AUR packages
│   ├── svc_enable.lst   # systemd services
│   ├── pkg_install.sh
│   ├── restore_cfg.sh   # deploys dotfiles (symlinks)
│   ├── restore_svc.sh
│   ├── install_zsh.sh
│   ├── install_pomodoro.sh
│   └── install_claude.sh
├── Configs/             # all ~/.config/ files
├── local-bin/           # scripts → ~/.local/bin/
├── home/                # home dotfiles (.zshrc)
├── system/              # system config (greetd)
└── Wallpapers/          # sample wallpaper
```

## Notes

- `monitors.conf` defaults to `monitor=,preferred,auto,1` (auto-detect all displays). Use `nwg-displays` to generate a proper config after logging in.
- Existing config files are backed up to `~/.config-backup-<timestamp>/` before being replaced.
- `waybar-module-pomodoro` is built from source: [Andeskjerf/waybar-module-pomodoro](https://github.com/Andeskjerf/waybar-module-pomodoro)
