#!/usr/bin/env bash
# archScratch - emergency package install
# Run this if pkg_install.sh fails: bash Scripts/emergency_pkg.sh
#
# This reuses the SAME package lists as the normal installer (no drift) and the
# same resilient per-package install, so "recovery" produces the same system.

source "$(dirname "$0")/global_fn.sh"

print_header "Emergency package install (resilient, from pkg_pacman.lst)"
mapfile -t pkgs < <(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/Scripts/pkg_pacman.lst")
pac_install "${pkgs[@]}" || print_warn "Some packages were skipped (see above)."

if command -v yay &>/dev/null; then
    print_header "Installing AUR packages"
    while IFS= read -r p || [[ -n "$p" ]]; do
        [[ "$p" =~ ^[[:space:]]*# || -z "${p//[[:space:]]/}" ]] && continue
        yay -S --needed --noconfirm "$p" || print_warn "AUR package failed: $p"
    done < "$DOTFILES_DIR/Scripts/pkg_aur.lst"
else
    print_warn "yay not installed — skipping AUR packages"
fi

print_header "Enabling core services"
# Note: no tlp here — it conflicts with power-profiles-daemon on ASUS and was
# removed from the package set. greetd is enabled LAST, once everything else is up.
for svc in NetworkManager bluetooth docker systemd-resolved greetd; do
    sudo systemctl enable --now "$svc" 2>/dev/null \
        && print_ok "Enabled: $svc" \
        || print_warn "Could not enable: $svc"
done

print_ok "Done — reboot to reach the greetd login screen"
