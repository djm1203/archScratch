#!/usr/bin/env bash
# archScratch - install oh-my-zsh, powerlevel10k, and plugins

source "$(dirname "$0")/global_fn.sh"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_omz() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_ok "oh-my-zsh already installed"
        return
    fi
    print_header "Installing oh-my-zsh"
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    print_ok "oh-my-zsh installed"
}

install_p10k() {
    # Prefer the pacman package (.zshrc sources it from /usr/share); only git-clone
    # as a fallback when the package isn't present (drops a network dependency).
    if [[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
        print_ok "powerlevel10k provided by pacman package"
        return
    fi
    local dest="$ZSH_CUSTOM/themes/powerlevel10k"
    if [[ -d "$dest" ]]; then
        print_ok "powerlevel10k already installed (git)"
        return
    fi
    print_header "Installing powerlevel10k (git fallback)"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest"
    print_ok "powerlevel10k installed"
}

install_plugins() {
    print_header "Installing zsh plugins"

    if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        print_ok "zsh-autosuggestions provided by pacman package"
    else
        local as_dir="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        if [[ ! -d "$as_dir" ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$as_dir"
            print_ok "zsh-autosuggestions installed (git fallback)"
        else
            print_ok "zsh-autosuggestions already installed (git)"
        fi
    fi

    if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        print_ok "zsh-syntax-highlighting provided by pacman package"
    else
        local sh_dir="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        if [[ ! -d "$sh_dir" ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$sh_dir"
            print_ok "zsh-syntax-highlighting installed (git fallback)"
        else
            print_ok "zsh-syntax-highlighting already installed (git)"
        fi
    fi
}

set_default_shell() {
    print_header "Setting zsh as default shell"
    local zsh_path
    zsh_path="$(command -v zsh)" || { print_warn "zsh not found; skipping chsh"; return; }
    # chsh refuses shells that aren't listed in /etc/shells.
    grep -qx "$zsh_path" /etc/shells 2>/dev/null \
        || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    if [[ "$SHELL" == "$zsh_path" ]]; then
        print_ok "zsh already default shell"
    elif chsh -s "$zsh_path"; then
        print_ok "Default shell set to zsh (takes effect on next login)"
    else
        print_warn "chsh failed — run 'chsh -s $zsh_path' manually later"
    fi
}

main() {
    install_omz
    install_p10k
    install_plugins
    set_default_shell
    echo -e "\n${YELLOW}  [!]${NC} Run 'p10k configure' on first zsh login to set up your prompt."
}

main "$@"
