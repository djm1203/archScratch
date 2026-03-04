#!/usr/bin/env bash
# archScratch - emergency package install
# Run this if pkg_install.sh fails: bash Scripts/emergency_pkg.sh

source "$(dirname "$0")/global_fn.sh"

print_header "Installing core packages"
sudo pacman -S --needed \
  waybar wofi foot mako swww hypridle hyprlock greetd \
  xdg-desktop-portal xdg-desktop-portal-hyprland \
  polkit-gnome pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol \
  networkmanager network-manager-applet blueman bluez bluez-utils \
  dolphin kio-extras ark kitty brightnessctl playerctl wl-clipboard grim slurp \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji inter-font woff2-font-awesome \
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum papirus-icon-theme breeze \
  fastfetch btop neovim nodejs npm git github-cli ripgrep fd \
  python-pip python-pipx go rustup docker docker-compose \
  obsidian firefox zathura zathura-pdf-mupdf torbrowser-launcher \
  openssh curl unzip man-db gnome-keyring \
  xdg-user-dirs libnotify hyprland

# AUR packages (waypaper, spotify, kvantum catppuccin theme)
if command -v yay &>/dev/null; then
    print_header "Installing AUR packages"
    yay -S --needed --noconfirm waypaper spotify kvantum-theme-catppuccin-git
else
    print_warn "yay not installed — skipping AUR packages (waypaper, spotify)"
fi

print_header "Enabling services"
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now docker
sudo systemctl enable --now tlp
sudo systemctl enable --now greetd

print_ok "Done — greetd should start now and drop you into the login screen"
