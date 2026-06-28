#!/usr/bin/env bash
# archScratch - enable systemd services

source "$(dirname "$0")/global_fn.sh"

enable_services() {
    print_header "Enabling systemd services"
    local lst="$DOTFILES_DIR/Scripts/svc_enable.lst"

    local err
    # `|| [[ -n "$svc" ]]` processes a final line that lacks a trailing newline.
    while IFS= read -r svc || [[ -n "$svc" ]]; do
        [[ "$svc" =~ ^[[:space:]]*# || -z "${svc//[[:space:]]/}" ]] && continue
        if err=$(sudo systemctl enable --now "$svc" 2>&1); then
            print_ok "Enabled: $svc"
        else
            # Surface the real reason instead of hiding it behind /dev/null.
            print_warn "Could not enable $svc: ${err##*$'\n'}"
        fi
    done < "$lst"
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

main() {
    enable_services
    setup_firewall
    setup_resolved
}

main "$@"
