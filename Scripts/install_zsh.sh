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
    local dest="$ZSH_CUSTOM/themes/powerlevel10k"
    if [[ -d "$dest" ]]; then
        print_ok "powerlevel10k already installed"
        return
    fi
    print_header "Installing powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest"
    print_ok "powerlevel10k installed"
}

install_plugins() {
    print_header "Installing zsh plugins"

    local as_dir="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    if [[ ! -d "$as_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$as_dir"
        print_ok "zsh-autosuggestions installed"
    else
        print_ok "zsh-autosuggestions already installed"
    fi

    local sh_dir="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$sh_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$sh_dir"
        print_ok "zsh-syntax-highlighting installed"
    else
        print_ok "zsh-syntax-highlighting already installed"
    fi
}

set_default_shell() {
    print_header "Setting zsh as default shell"
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        chsh -s "$(which zsh)"
        print_ok "Default shell set to zsh (takes effect on next login)"
    else
        print_ok "zsh already default shell"
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
