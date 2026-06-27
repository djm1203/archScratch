#!/usr/bin/env bash
# archScratch - enable systemd services

source "$(dirname "$0")/global_fn.sh"

main() {
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

main "$@"
