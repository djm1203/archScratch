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

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
