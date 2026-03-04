#!/usr/bin/env bash
# archScratch - install Claude Code CLI

source "$(dirname "$0")/global_fn.sh"

main() {
    if command -v claude &>/dev/null; then
        print_ok "Claude Code already installed ($(claude --version 2>/dev/null | head -1))"
        return
    fi

    print_header "Installing Claude Code"

    if ! command -v npm &>/dev/null; then
        print_warn "npm not found — installing nodejs and npm"
        sudo pacman -S --needed --noconfirm nodejs npm
        hash -r
    fi

    npm install -g @anthropic-ai/claude-code
    print_ok "Claude Code installed"
}

main "$@"
