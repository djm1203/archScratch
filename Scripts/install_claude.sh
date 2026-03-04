#!/usr/bin/env bash
# archScratch - install Claude Code CLI

source "$(dirname "$0")/global_fn.sh"

main() {
    if command -v claude &>/dev/null; then
        print_ok "Claude Code already installed ($(claude --version 2>/dev/null | head -1))"
        return
    fi

    print_header "Installing Claude Code"

    if ! command -v curl &>/dev/null; then
        sudo pacman -S --needed --noconfirm curl
    fi

    curl -fsSL https://claude.ai/install.sh | bash
    print_ok "Claude Code installed"
}

main "$@"
