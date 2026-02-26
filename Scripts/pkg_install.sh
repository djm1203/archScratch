#!/usr/bin/env bash
# archScratch - package installation

source "$(dirname "$0")/global_fn.sh"

install_yay() {
    if command -v yay &>/dev/null; then
        print_ok "yay already installed"
        return
    fi
    print_header "Installing yay (AUR helper)"
    sudo pacman -S --needed git base-devel --noconfirm
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    print_ok "yay installed"
}

install_pacman_packages() {
    print_header "Installing pacman packages"
    local lst="$DOTFILES_DIR/Scripts/pkg_pacman.lst"

    # Strip comments and blank lines, then install
    grep -v '^\s*#' "$lst" | grep -v '^\s*$' | sudo pacman -S --needed --noconfirm -
    print_ok "Pacman packages installed"
}

install_aur_packages() {
    print_header "Installing AUR packages"
    local lst="$DOTFILES_DIR/Scripts/pkg_aur.lst"

    grep -v '^\s*#' "$lst" | grep -v '^\s*$' | xargs yay -S --needed --noconfirm
    print_ok "AUR packages installed"
}

prompt_microcode() {
    print_header "CPU Microcode"
    echo -e "  Select your CPU type:"
    echo -e "  1) Intel"
    echo -e "  2) AMD"
    echo -e "  3) Skip"
    read -rp "$(echo -e "${YELLOW}  [?]${NC} Choice [1/2/3]: ")" choice
    case "$choice" in
        1) sudo pacman -S --needed --noconfirm intel-ucode && print_ok "intel-ucode installed" ;;
        2) sudo pacman -S --needed --noconfirm amd-ucode  && print_ok "amd-ucode installed"   ;;
        *) print_warn "Skipping microcode" ;;
    esac
}

prompt_nvidia() {
    print_header "NVIDIA GPU"
    if ask_yes_no "Do you have an NVIDIA GPU?"; then
        print_header "Installing NVIDIA drivers"
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings
        print_ok "NVIDIA drivers installed"

        if ask_yes_no "Is this an ASUS laptop (ROG/TUF - needs asusctl/supergfxctl)?"; then
            yay -S --needed --noconfirm asusctl supergfxctl
            sudo systemctl enable --now asusd supergfxd
            print_ok "ASUS tools installed and enabled"
        fi
    else
        print_ok "Skipping NVIDIA setup"
    fi
}

main() {
    sudo pacman -Syu --noconfirm
    install_yay
    install_pacman_packages
    install_aur_packages
    prompt_microcode
    prompt_nvidia
}

main "$@"
