#!/usr/bin/env bash
# archScratch - dotfiles installer
# Usage: git clone git@github.com:djm1203/archScratch.git && cd archScratch && ./install.sh
#
# Run this after a fresh Arch Linux install with base packages.

# Intentionally NOT using `set -e`: one failing step must not abort the whole
# install (PR-2). Each step is run via run_step(), which records pass/fail and
# prints a summary at the end.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/Scripts/global_fn.sh"

# Make freshly-installed tools reachable for the rest of this run.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Log everything to a file for post-mortem debugging (B-008).
LOG="$HOME/archscratch-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

# ─── Step runner ──────────────────────────────────────────────────────────────

STEP_RESULTS=()

run_step() {
    local label="$1"; shift
    print_header "▶ $label"
    if "$@"; then
        STEP_RESULTS+=("  [OK]   $label")
    else
        STEP_RESULTS+=("  [FAIL] $label")
        print_err "Step failed: $label — continuing with the rest of the install."
    fi
}

verify_install() {
    print_header "Verifying key binaries"
    local b missing=()
    for b in hyprland waybar wofi swww mako foot kitty nvim code git docker ruby; do
        if command -v "$b" &>/dev/null; then
            print_ok "found: $b"
        else
            print_warn "MISSING: $b"
            missing+=("$b")
        fi
    done
    if ((${#missing[@]})); then
        STEP_RESULTS+=("  [WARN] Missing binaries: ${missing[*]}")
    fi
}

print_summary() {
    print_header "Install summary"
    local line
    for line in "${STEP_RESULTS[@]}"; do
        if [[ "$line" == *"[FAIL]"* ]]; then
            echo -e "${RED}${line}${NC}"
        else
            echo -e "${GREEN}${line}${NC}"
        fi
    done
    echo -e "\n  Full log: ${CYAN}$LOG${NC}"
}

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
    # ICMP is blocked on some networks, so fall back to an HTTPS HEAD request.
    if ping -c1 archlinux.org &>/dev/null; then
        return 0
    fi
    if curl -fsI https://archlinux.org &>/dev/null; then
        return 0
    fi
    print_err "No internet connection detected."
    exit 1
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
    run_step "Packages (pacman + AUR + drivers)" bash "$DOTFILES_DIR/Scripts/pkg_install.sh"

    # 2. Zsh + oh-my-zsh + p10k
    run_step "Zsh / oh-my-zsh / powerlevel10k" bash "$DOTFILES_DIR/Scripts/install_zsh.sh"

    # 3. waybar-module-pomodoro (built from source)
    run_step "waybar-module-pomodoro (source build)" bash "$DOTFILES_DIR/Scripts/install_pomodoro.sh"

    # 4. Git / GitHub SSH setup
    run_step "Git / GitHub accounts" bash "$DOTFILES_DIR/Scripts/install_git_accounts.sh"

    # 5. Claude Code (optional)
    if ask_yes_no "Install Claude Code CLI?"; then
        run_step "Claude Code CLI" bash "$DOTFILES_DIR/Scripts/install_claude.sh"
    fi

    # 6. Deploy dotfiles
    run_step "Deploy dotfiles" bash "$DOTFILES_DIR/Scripts/restore_cfg.sh"

    # 7. Enable services
    run_step "Enable systemd services" bash "$DOTFILES_DIR/Scripts/restore_svc.sh"

    verify_install
    print_summary

    # 9. Done
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
