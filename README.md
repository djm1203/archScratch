# archScratch

Personal Arch Linux dotfiles — Hyprland desktop setup. Clone and run one command to get a fully configured system.

## Stack

| Component       | Package                        |
|-----------------|-------------------------------|
| Compositor      | Hyprland                      |
| Display Manager | greetd + tuigreet              |
| Bar             | Waybar                        |
| App Launcher    | Wofi                          |
| Notifications   | Mako                          |
| Wallpaper       | awww + Waypaper (mpvpaper for video: `wallpaper-video`) |
| Lock / Idle     | Hyprlock + Hypridle           |
| File Manager    | Dolphin                       |
| Terminal        | Foot (default) · Kitty (for a background image) |
| Shell           | Zsh + oh-my-zsh + Powerlevel10k |
| Editors         | Neovim (LazyVim) · VS Code    |
| Dev tooling     | node, go, rust, ruby + rails, docker, lazygit, fzf, ripgrep, fd, bat, eza, jq, tmux, gdb, cmake |
| Theme           | Switchable: Gruvbox (default), Monokai, Catppuccin, Nord, Rosé Pine, Tokyo Night |
| Icons / GTK     | Gruvbox Plus icons, gruvbox-dark-gtk |
| Fonts           | JetBrains Mono Nerd, Inter    |

## Install guide (start here)

### 1. Install the Arch base system

Boot the Arch ISO and run `archinstall`. Choose:

- **Profile:** Minimal (no desktop; this repo installs Hyprland)
- **Network:** NetworkManager
- **User:** create a normal user with sudo rights (never run the installer as root)
- **Extra packages:** `git`
- **Bootloader / filesystem:** your choice (GRUB or systemd-boot; ext4 or btrfs)

Reboot, log in on the text console, and get online:

```bash
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"   # skip if on ethernet
```

### 2. Clone and run

```bash
git clone https://github.com/djm1203/archScratch.git   # HTTPS: no SSH key exists yet
cd archScratch
./install.sh
```

It asks a few questions, then installs for a while (it downloads a lot). It does not stop on a single failed
package; a pass/fail summary and a log (`~/archscratch-install-<timestamp>.log`) come at the end.

### 3. What to answer, by machine

| Prompt | ThinkPad T480 | ASUS ROG / NVIDIA laptop | Other PC / laptop |
|---|---|---|---|
| Hardware profile | **2** (ThinkPad; it's the default if detected) | **1** (ASUS) | **3** (Other) |
| CPU microcode | **1** Intel (default) | Intel or AMD to match your CPU | to match your CPU |
| NVIDIA GPU? | **No** (MX150 is too old for the open driver; the Intel GPU is plenty) | **Yes** | Yes only if you have one |
| Claude Code? | Yes | Yes | Yes |
| Fingerprint reader? | Yes if offered (see ThinkPad notes) | Only offered if a supported reader is found | same |
| Boot splash (Plymouth)? | Skip the first time; add later with `bash Scripts/install_plymouth.sh` | same | same |
| Git setup | Your name, then single or work + personal accounts (creates SSH keys) | same | same |
| Reboot now? | Yes | Yes | Yes |

What each machine gets beyond the common base (Hyprland, themes, dev tools, Proton VPN):

| | ThinkPad T480 | ASUS ROG / NVIDIA | Other |
|---|---|---|---|
| Power | `tlp` (battery held at 75-80%) + `throttled` (fixes CPU throttling) | `asusctl` + `power-profiles-daemon` | none extra |
| Graphics | Intel video acceleration, `vulkan-intel` | `nvidia-open-dkms` (ASUS) or `nvidia-dkms` + matching kernel headers, NVIDIA suspend services | per your answers |
| Kernel | stock | `linux-g14` from the asus-linux repo | stock |
| Input | TrackPoint middle-button scrolling, faster touchpad | n/a | n/a |
| Extras | Thunderbolt `bolt`, optional fingerprint | `rog-control-center` | n/a |

### 4. First boot

1. At the login screen (`tuigreet`) log in with your **password** (not fingerprint). Hyprland starts.
2. `Super+T` opens a terminal. Run `p10k configure` once to set up the prompt.
3. Put wallpapers in `~/Pictures/Wallpapers/gruvbox/` (none ship in the repo), then `Super+W` to pick one.
4. `Super+Shift+W` switches the color theme (Gruvbox, Monokai, Catppuccin, Nord, Rosé Pine, Tokyo Night).
5. Sign in to Proton VPN from the app launcher (`Super+R`). It lives in the tray.

**ThinkPad T480 checklist**

- `hyprctl devices`: confirm the TrackPoint is named `tpps/2-elan-trackpoint`. If not, fix the name in `Scripts/restore_cfg.sh` and rerun `./install.sh --upgrade`.
- `sudo throttled --monitor`: watch the CPU power limits (the T480's known throttling).
- `tlp-stat -b`: check the 75-80% charge limits. `sudo tlp fullcharge BAT0` charges to 100% once (e.g. before travel).
- BIOS: if it offers a Linux/S3 sleep mode, pick it for better suspend.
- **Fingerprint** (reader 06cb:009a): stock Arch drivers don't support it, so the installer uses AUR `python-validity` + `open-fprintd`.
  Run `fprintd-enroll`, then `fprintd-verify`, then `bash Scripts/fingerprint_pam.sh` to enable it for `sudo`
  (password stays as the fallback; undo with `--undo`). It's deliberately not used at login (it can't unlock the keyring).
  This is the most fragile part; if it fails, check `systemctl status python3-validity`.

**ASUS ROG / NVIDIA checklist**

- Reboot once so the NVIDIA module and `linux-g14` kernel load; check `nvidia-smi`.
- `hypr/machine.lua` (generated) holds the NVIDIA settings; if the cursor is invisible or Electron apps look blurry, see the NVIDIA notes at https://wiki.hypr.land.
- Power profiles: `powerprofilesctl`; ASUS controls: `rog-control-center`.
- Set your monitor layout in `Configs/hypr/monitors.lua` (see `hyprctl monitors`).

### 5. If something goes wrong

| Symptom | Fix |
|---|---|
| Hyprland shows an error banner | `hyprctl configerrors` lists the bad line in `~/.config/hypr/hyprland.lua` |
| Bar / launcher / terminal colors missing | `theme-switch --init` (needs `gettext`, which the installer adds) |
| A package failed to install | Read the install log; rerun `./install.sh --upgrade` (safe to repeat) |
| Package step broke pacman | `bash Scripts/emergency_pkg.sh` |
| Black screen after reboot | `Ctrl+Alt+F2`, log in, run `journalctl -b -p err` and `Hyprland` to see the error |

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
- Set your monitor layout in `Configs/hypr/monitors.lua` (`hyprctl monitors` lists outputs)
- `Super+W` opens the wallpaper picker. Wallpapers live in `~/Pictures/Wallpapers/` — theme-specific
  ones go in `~/Pictures/Wallpapers/<theme>/` (e.g. `gruvbox/`); none ship in the repo, add your own
- **Wallpapers auto-rotate** every 15 min via a systemd user timer (`wallpaper-rotate.timer`).
  Drop more images into `Wallpapers/` (they deploy to `~/Pictures/Wallpapers/`).
- **Terminal background image:** open Kitty with `Super+Shift+T` and place your image at
  `~/.config/kitty/bg.png` (i.e. `Configs/kitty/bg.png` in the repo). Foot stays the default
  terminal and uses transparency over the wallpaper instead.

## Themes

`Super+Shift+W` (or `theme-switch <name>`) switches the whole desktop live: Hyprland, Waybar,
Wofi, Mako, Kitty, Foot and the wallpaper folder `~/Pictures/Wallpapers/<theme>/`. Palettes live
in `Configs/theme/palettes/*.env` (one file per theme, MIT-licensed values from
[tinted-theming](https://github.com/tinted-theming/schemes) where available); copy one to add a
theme. GTK/Qt stay on Gruvbox, and Neovim keeps LazyVim's own colorscheme.

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
| `Super+Shift+W`      | Switch color theme      |
| `Super+Shift+P`      | Color picker (hyprpicker) |
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
│   ├── install_plymouth.sh # opt-in boot splash (Gruvbox)
│   ├── install_fingerprint.sh / fingerprint_pam.sh # opt-in fingerprint reader (never auto-edits PAM)
│   └── emergency_pkg.sh # resilient recovery if pkg_install fails
├── Configs/             # all ~/.config/ files
│   ├── theme/           # palettes/*.env + templates (generated colors: see theme-switch)
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

- **Hyprland >= 0.57 uses Lua config** (`Configs/hypr/hyprland.lua`); the old `hyprland.conf` format is no longer read. `monitors.lua` defaults to every display at its preferred mode; pin a layout there if you want one (`hyprctl monitors` lists outputs). `hyprlock` and `hypridle` still use their own `.conf` files.
- Existing config files are backed up to `~/.config-backup-<timestamp>/` before being replaced.
- `waybar-module-pomodoro` is built from source: [Andeskjerf/waybar-module-pomodoro](https://github.com/Andeskjerf/waybar-module-pomodoro)
