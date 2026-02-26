#!/usr/bin/env bash
# archScratch - dotfiles installer
# Usage: git clone git@github.com:djm1203/archScratch.git && cd archScratch && ./install.sh
#
# Run this after a fresh Arch Linux install with base packages.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/Scripts/global_fn.sh"

# ─── Sanity checks ────────────────────────────────────────────────────────────

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        print_err "This script is designed for Arch Linux only."
        exit 1
    fi
}

check_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        print_err "Do not run this script as root. Run as your regular user (sudo access required)."
        exit 1
    fi
}

check_internet() {
    if ! ping -c1 archlinux.org &>/dev/null; then
        print_err "No internet connection detected."
        exit 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  █████╗ ██████╗  ██████╗██╗  ██╗███████╗ ██████╗██████╗  █████╗ ████████╗ ██████╗██╗  ██╗"
    echo " ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
    echo " ███████║██████╔╝██║     ███████║███████╗██║     ██████╔╝███████║   ██║   ██║     ███████║"
    echo " ██╔══██║██╔══██╗██║     ██╔══██║╚════██║██║     ██╔══██╗██╔══██║   ██║   ██║     ██╔══██║"
    echo " ██║  ██║██║  ██║╚██████╗██║  ██║███████║╚██████╗██║  ██║██║  ██║   ██║   ╚██████╗██║  ██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "  Hyprland dotfiles by djm1203\n"

    check_arch
    check_not_root
    check_internet

    print_header "Starting installation"
    echo -e "  Dotfiles dir: ${CYAN}$DOTFILES_DIR${NC}"
    echo -e "  User: ${CYAN}$USER${NC}"
    echo ""

    if ! ask_yes_no "Ready to install? This will install packages and deploy configs." "y"; then
        echo "Aborted."
        exit 0
    fi

    # 1. Packages
    bash "$DOTFILES_DIR/Scripts/pkg_install.sh"

    # 2. Zsh + oh-my-zsh + p10k
    bash "$DOTFILES_DIR/Scripts/install_zsh.sh"

    # 3. waybar-module-pomodoro (built from source)
    bash "$DOTFILES_DIR/Scripts/install_pomodoro.sh"

    # 4. Claude Code
    if ask_yes_no "Install Claude Code CLI?"; then
        bash "$DOTFILES_DIR/Scripts/install_claude.sh"
    fi

    # 5. Deploy dotfiles
    bash "$DOTFILES_DIR/Scripts/restore_cfg.sh"

    # 6. Enable services
    bash "$DOTFILES_DIR/Scripts/restore_svc.sh"

    # 7. Done
    print_header "Installation complete!"
    echo -e "
  ${GREEN}Next steps:${NC}
  1. Reboot your system
  2. On first zsh login, run: ${CYAN}p10k configure${NC}
  3. Run ${CYAN}nwg-displays${NC} to set up your monitor layout
  4. Set your wallpaper with ${CYAN}Super+W${NC} (waypaper)
  5. Log in and enjoy!

  ${YELLOW}Keybindings:${NC}
    Super+T        → terminal (foot)
    Super+B        → browser (firefox)
    Super+E        → file manager (dolphin)
    Super+R / A    → app launcher (wofi)
    Super+L        → lock screen
    Super+Escape   → power menu
    Super+W        → wallpaper picker
    Super+Shift+C  → toggle caffeine (prevent sleep)
"

    if ask_yes_no "Reboot now?"; then
        systemctl reboot
    fi
}

main "$@"
