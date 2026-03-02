#!/usr/bin/env bash
# archScratch - GitHub multi-account SSH setup

source "$(dirname "$0")/global_fn.sh"

setup_single_account() {
    print_header "Git single-account setup"
    read -rp "$(echo -e "${YELLOW}  [?]${NC} GitHub email: ")" email

    cat > "$HOME/.gitconfig" <<EOF
[user]
    name = Derek Martinez
    email = $email

[init]
    defaultBranch = main
EOF
    print_ok "~/.gitconfig written"

    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        print_ok "SSH key generated: ~/.ssh/id_ed25519"
        echo -e "\n${CYAN}  Add this key to GitHub → Settings → SSH Keys:${NC}"
        echo -e "${BOLD}$(cat "$HOME/.ssh/id_ed25519.pub")${NC}\n"
    else
        print_ok "SSH key already exists at ~/.ssh/id_ed25519"
    fi
}

setup_multi_account() {
    print_header "Git multi-account setup (work + personal)"

    read -rp "$(echo -e "${YELLOW}  [?]${NC} Work GitHub email: ")" work_email
    read -rp "$(echo -e "${YELLOW}  [?]${NC} Personal GitHub email: ")" personal_email

    # Generate SSH keypairs
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ ! -f "$HOME/.ssh/id_ed25519_work" ]]; then
        ssh-keygen -t ed25519 -C "$work_email" -f "$HOME/.ssh/id_ed25519_work" -N ""
        print_ok "Work SSH key generated: ~/.ssh/id_ed25519_work"
    else
        print_ok "Work SSH key already exists"
    fi

    if [[ ! -f "$HOME/.ssh/id_ed25519_personal" ]]; then
        ssh-keygen -t ed25519 -C "$personal_email" -f "$HOME/.ssh/id_ed25519_personal" -N ""
        print_ok "Personal SSH key generated: ~/.ssh/id_ed25519_personal"
    else
        print_ok "Personal SSH key already exists"
    fi

    # Create project directories
    mkdir -p "$HOME/Desktop/Quantum_Intelligence"
    mkdir -p "$HOME/Desktop/Personal"
    print_ok "Project directories created"

    # Write ~/.gitconfig
    cat > "$HOME/.gitconfig" <<EOF
[user]
    name = Derek Martinez

[init]
    defaultBranch = main

[includeIf "gitdir:~/Desktop/Quantum_Intelligence/"]
    path = ~/.gitconfig-work

[includeIf "gitdir:~/Desktop/Personal/"]
    path = ~/.gitconfig-personal
EOF
    print_ok "~/.gitconfig written"

    # Write ~/.gitconfig-work
    cat > "$HOME/.gitconfig-work" <<EOF
[user]
    email = $work_email

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work
EOF
    print_ok "~/.gitconfig-work written"

    # Write ~/.gitconfig-personal
    cat > "$HOME/.gitconfig-personal" <<EOF
[user]
    email = $personal_email

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_personal
EOF
    print_ok "~/.gitconfig-personal written"

    # Print public keys
    echo -e "\n${BOLD}${CYAN}  ══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  Add these keys to their respective GitHub accounts${NC}"
    echo -e "${BOLD}${CYAN}  Settings → SSH and GPG keys → New SSH key${NC}"
    echo -e "${BOLD}${CYAN}  ══════════════════════════════════════════════════${NC}\n"

    echo -e "${YELLOW}  WORK key${NC} (github.com → work account):"
    echo -e "${BOLD}$(cat "$HOME/.ssh/id_ed25519_work.pub")${NC}\n"

    echo -e "${YELLOW}  PERSONAL key${NC} (github.com → djm1203):"
    echo -e "${BOLD}$(cat "$HOME/.ssh/id_ed25519_personal.pub")${NC}\n"

    echo -e "${GREEN}  Usage:${NC}"
    echo -e "  # Work repo  → cd ~/Desktop/Quantum_Intelligence && git clone git@github.com:org/repo.git"
    echo -e "  # Personal   → cd ~/Desktop/Personal && git clone git@github.com:djm1203/repo.git"
    echo -e "  Git picks the right key + email automatically based on directory.\n"

    read -rp "$(echo -e "${YELLOW}  [!]${NC} Copy the keys above, then press Enter to continue...")"
}

main() {
    print_header "Git / GitHub setup"

    if ask_yes_no "Set up multi-account GitHub (work + personal)?"; then
        setup_multi_account
    else
        setup_single_account
    fi
}

main "$@"
