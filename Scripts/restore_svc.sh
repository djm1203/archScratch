#!/usr/bin/env bash
# archScratch - enable systemd services

source "$(dirname "$0")/global_fn.sh"

main() {
    print_header "Enabling systemd services"
    local lst="$DOTFILES_DIR/Scripts/svc_enable.lst"

    while IFS= read -r svc; do
        [[ "$svc" =~ ^#.*$ || -z "$svc" ]] && continue
        sudo systemctl enable --now "$svc" 2>/dev/null \
            && print_ok "Enabled: $svc" \
            || print_warn "Could not enable: $svc (may not exist yet)"
    done < "$lst"
}

main "$@"
