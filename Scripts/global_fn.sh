#!/usr/bin/env bash
# archScratch - shared functions and variables

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Respect an already-exported DOTFILES_DIR (set by install.sh); otherwise derive it.
: "${DOTFILES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

print_header() {
    echo -e "\n${BOLD}${CYAN}==> $1${NC}"
}

print_ok() {
    echo -e "${GREEN}  [OK]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}  [WARN]${NC} $1"
}

print_err() {
    echo -e "${RED}  [ERR]${NC} $1"
}

# Install pacman packages resiliently: try one fast batch, and if that fails,
# retry package-by-package so a single bad/renamed package can't abort the rest.
# Returns non-zero if anything was skipped (and warns which).
pac_install() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0

    if sudo pacman -S --needed --noconfirm "${pkgs[@]}"; then
        return 0
    fi

    print_warn "Batch install hit an error — retrying package-by-package…"
    local p failed=()
    for p in "${pkgs[@]}"; do
        sudo pacman -S --needed --noconfirm "$p" || failed+=("$p")
    done

    if ((${#failed[@]})); then
        print_warn "Skipped (could not install): ${failed[*]}"
        return 1
    fi
    return 0
}

# Prompt for a value with a default (Enter accepts the default). The prompt goes
# to stderr so the chosen value can be captured with: x=$(ask_default "..." "def")
ask_default() {
    local prompt="$1" default="$2" ans
    read -rp "$(echo -e "${YELLOW}  [?]${NC} ${prompt} [${default}]: ")" ans
    echo "${ans:-$default}"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local yn
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "${YELLOW}  [?]${NC} $prompt [Y/n]: ")" yn
        yn="${yn:-y}"
    else
        read -rp "$(echo -e "${YELLOW}  [?]${NC} $prompt [y/N]: ")" yn
        yn="${yn:-n}"
    fi
    [[ "$yn" =~ ^[Yy]$ ]]
}
