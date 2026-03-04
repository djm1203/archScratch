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

    # Configure npm to install to user directory (avoids root/permission errors)
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"

    npm install -g @anthropic-ai/claude-code

    # Persist npm global bin in .zshrc if not already there
    if ! grep -q 'npm-global' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
    fi

    print_ok "Claude Code installed to ~/.npm-global/bin/"
}

main "$@"
