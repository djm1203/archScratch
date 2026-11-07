#!/usr/bin/env bash
# archScratch - OPT-IN fingerprint reader setup (packages + services only).
# Never edits PAM: run Scripts/fingerprint_pam.sh yourself after enrolling.
#   06cb:009a (ThinkPad T480 "Prometheus")  -> AUR python-validity + open-fprintd
#   06cb:00bd (Synaptics MIS)                -> stock fprintd (libfprint supports it)
# Upstream libfprint does not support 009a yet; revisit if MR !626 merges.

source "$(dirname "$0")/global_fn.sh"

main() {
    command -v lsusb &>/dev/null || sudo pacman -S --needed --noconfirm usbutils
    local ids
    ids="$(lsusb | grep -Eio '(06cb:009a|06cb:00bd)' | head -1)"

    case "$ids" in
        06cb:00bd)
            print_header "Fingerprint reader $ids: using stock fprintd"
            sudo pacman -S --needed --noconfirm fprintd || return 1
            ;;
        06cb:009a)
            print_header "Fingerprint reader $ids: python-validity + open-fprintd (AUR)"
            command -v yay &>/dev/null || { print_err "yay not installed"; return 1; }
            # open-fprintd replaces fprintd; both own the same D-Bus name.
            if pacman -Qq fprintd &>/dev/null; then
                print_warn "Removing stock fprintd (conflicts with open-fprintd)"
                sudo pacman -Rns --noconfirm fprintd || return 1
            fi
            yay -S --needed --noconfirm python-validity open-fprintd fprintd-clients-git || return 1
            local svc
            for svc in python3-validity open-fprintd open-fprintd-suspend open-fprintd-resume; do
                sudo systemctl enable --now "$svc.service" \
                    && print_ok "Enabled: $svc" || print_warn "Could not enable $svc (check: systemctl list-unit-files | grep -Ei 'validity|fprint')"
            done
            ;;
        *)
            print_warn "No supported fingerprint reader found (looked for 06cb:009a, 06cb:00bd) — skipping"
            return 0
            ;;
    esac

    echo
    print_ok "Next: 'fprintd-enroll' then 'fprintd-verify', then (optional) 'bash Scripts/fingerprint_pam.sh'"
    print_warn "Not for login (greetd): a fingerprint can't unlock gnome-keyring. Use it for sudo + lock screen."
}

main "$@"
