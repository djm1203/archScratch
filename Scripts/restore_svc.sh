#!/usr/bin/env bash
# archScratch - enable systemd services

source "$(dirname "$0")/global_fn.sh"

enable_services() {
    print_header "Enabling systemd services"
    local lst="$DOTFILES_DIR/Scripts/svc_enable.lst"

    local err now
    # `|| [[ -n "$svc" ]]` processes a final line that lacks a trailing newline.
    while IFS= read -r svc || [[ -n "$svc" ]]; do
        [[ "$svc" =~ ^[[:space:]]*# || -z "${svc//[[:space:]]/}" ]] && continue
        # greetd is enabled but NOT started: --now would kill the installer's TTY.
        now="--now"; [[ "$svc" == greetd ]] && now=""
        # Don't restart networking out from under the installer if iwd/networkd manages it.
        if [[ "$svc" == NetworkManager ]] && { systemctl is-active --quiet iwd || systemctl is-active --quiet systemd-networkd; }; then
            now=""; print_warn "iwd/systemd-networkd is active: enabling NetworkManager for next boot only"
        fi
        if err=$(sudo systemctl enable $now "$svc" 2>&1); then
            print_ok "Enabled: $svc"
        else
            # Surface the real reason instead of hiding it behind /dev/null.
            print_warn "Could not enable $svc: ${err##*$'\n'}"
        fi
    done < "$lst"

    # ThinkPad profile services: only when pkg_install.sh installed them.
    if pacman -Qq tlp &>/dev/null; then
        # tlp manages radios itself; the systemd units fight it.
        sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket >/dev/null 2>&1
    fi
    for svc in tlp throttled; do
        if pacman -Qq "$svc" &>/dev/null; then
            sudo systemctl enable --now "$svc.service" && print_ok "Enabled: $svc"
        fi
    done
}

setup_firewall() {
    command -v ufw &>/dev/null || { print_warn "ufw not installed — skipping firewall"; return 0; }
    print_header "Configuring firewall (ufw)"
    sudo ufw default deny incoming  >/dev/null
    sudo ufw default allow outgoing >/dev/null
    sudo ufw --force enable          >/dev/null
    sudo systemctl enable ufw.service 2>/dev/null
    print_ok "ufw enabled (deny incoming / allow outgoing)"
}

setup_resolved() {
    # Only wire DNS through systemd-resolved if it's actually enabled.
    systemctl is-enabled systemd-resolved &>/dev/null || return 0
    print_header "Wiring NetworkManager → systemd-resolved"
    sudo mkdir -p /etc/NetworkManager/conf.d
    printf '[main]\ndns=systemd-resolved\n' \
        | sudo tee /etc/NetworkManager/conf.d/dns.conf >/dev/null
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    sudo systemctl reload NetworkManager 2>/dev/null || true
    print_ok "systemd-resolved DNS configured"
}

setup_docker_group() {
    # Let the user run docker without sudo. Takes effect on next login.
    getent group docker >/dev/null || return 0
    if id -nG "$(id -un)" | grep -qw docker; then
        print_ok "User already in docker group"
        return 0
    fi
    if sudo usermod -aG docker "$(id -un)"; then
        print_ok "Added $(id -un) to docker group (log out/in to take effect)"
    else
        print_warn "Could not add $(id -un) to docker group"
    fi
}

main() {
    enable_services
    setup_firewall
    setup_resolved
    setup_docker_group
}

main "$@"
