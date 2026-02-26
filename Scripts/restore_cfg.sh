#!/usr/bin/env bash
# archScratch - deploy dotfiles (symlinks with backup)

source "$(dirname "$0")/global_fn.sh"

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

backup_and_link() {
    local src="$1"   # source file/dir in repo
    local dest="$2"  # destination path

    if [[ -e "$dest" && ! -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
        print_warn "Backed up existing $dest → $BACKUP_DIR/"
    elif [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    print_ok "Linked $dest"
}

deploy_configs() {
    print_header "Deploying ~/.config dotfiles"
    local cfg="$DOTFILES_DIR/Configs"

    backup_and_link "$cfg/hypr"        "$HOME/.config/hypr"
    backup_and_link "$cfg/waybar"      "$HOME/.config/waybar"
    backup_and_link "$cfg/foot"        "$HOME/.config/foot"
    backup_and_link "$cfg/wofi"        "$HOME/.config/wofi"
    backup_and_link "$cfg/mako"        "$HOME/.config/mako"
    backup_and_link "$cfg/nvim"        "$HOME/.config/nvim"
    backup_and_link "$cfg/fastfetch"   "$HOME/.config/fastfetch"
    backup_and_link "$cfg/gtk-3.0"     "$HOME/.config/gtk-3.0"
    backup_and_link "$cfg/gtk-4.0"     "$HOME/.config/gtk-4.0"
    backup_and_link "$cfg/Kvantum"     "$HOME/.config/Kvantum"
    backup_and_link "$cfg/qt5ct"       "$HOME/.config/qt5ct"
    backup_and_link "$cfg/qt6ct"       "$HOME/.config/qt6ct"
    backup_and_link "$cfg/waypaper"    "$HOME/.config/waypaper"
    backup_and_link "$cfg/zathura"     "$HOME/.config/zathura"
}

deploy_local_bin() {
    print_header "Deploying ~/.local/bin scripts"
    mkdir -p "$HOME/.local/bin"
    for script in "$DOTFILES_DIR/local-bin/"*; do
        local name
        name=$(basename "$script")
        chmod +x "$script"
        backup_and_link "$script" "$HOME/.local/bin/$name"
    done
}

deploy_home_files() {
    print_header "Deploying home dotfiles"
    backup_and_link "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"
}

deploy_wallpapers() {
    print_header "Setting up wallpapers"
    mkdir -p "$HOME/Pictures/Wallpapers"
    if [[ ! -f "$HOME/Pictures/Wallpapers/moon.png" ]]; then
        cp "$DOTFILES_DIR/Wallpapers/moon.png" "$HOME/Pictures/Wallpapers/moon.png"
        print_ok "Sample wallpaper copied to ~/Pictures/Wallpapers/"
    else
        print_ok "Wallpaper already exists, skipping"
    fi
}

deploy_greetd() {
    print_header "Configuring greetd"
    local cfg="$DOTFILES_DIR/system/greetd-config.toml"
    local dest="/etc/greetd/config.toml"
    # Replace placeholder username with current user
    sudo mkdir -p /etc/greetd
    sed "s/{{USER}}/$USER/g" "$cfg" | sudo tee "$dest" > /dev/null
    print_ok "greetd configured for user: $USER"
}

main() {
    deploy_configs
    deploy_local_bin
    deploy_home_files
    deploy_wallpapers
    deploy_greetd
    print_ok "All dotfiles deployed"
    [[ -d "$BACKUP_DIR" ]] && print_warn "Backups saved to: $BACKUP_DIR"
}

main "$@"
