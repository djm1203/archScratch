#!/usr/bin/env bash
# archScratch - OPT-IN Plymouth boot splash (Catppuccin Mocha).
# Run directly:  bash Scripts/install_plymouth.sh
# Or via the installer's optional prompt (passes --yes).
#
# ⚠ This edits /etc/mkinitcpio.conf, the kernel command line, and rebuilds the
#   initramfs. A bad cmdline won't usually make you unbootable, but TEST IN A VM
#   FIRST. You can revert by removing 'plymouth' from HOOKS and 'splash' from the
#   cmdline, then rebuilding the initramfs.

source "$(dirname "$0")/global_fn.sh"

add_plymouth_hook() {
    if grep -q 'plymouth' /etc/mkinitcpio.conf; then
        print_ok "plymouth hook already present in mkinitcpio.conf"
        return
    fi
    # Insert 'plymouth' right after 'udev' on the HOOKS line.
    sudo sed -i '/^HOOKS=/ { /plymouth/! s/\budev\b/udev plymouth/ }' /etc/mkinitcpio.conf
    if grep -q 'plymouth' /etc/mkinitcpio.conf; then
        print_ok "Added plymouth hook"
    else
        print_warn "Could not edit HOOKS — add 'plymouth' after 'udev' in /etc/mkinitcpio.conf manually"
    fi
}

add_splash_cmdline() {
    local done_any=0

    # systemd-boot loader entries
    if [[ -d /boot/loader/entries ]]; then
        local f
        for f in /boot/loader/entries/*.conf; do
            [[ -f "$f" ]] || continue
            grep -q '^options' "$f" || continue
            grep -q 'splash' "$f" && continue
            sudo sed -i '/^options/ s/$/ quiet splash/' "$f"
            done_any=1
        done
        [[ $done_any -eq 1 ]] && print_ok "Added 'quiet splash' to systemd-boot entries"
    fi

    # UKI / mkinitcpio cmdline file
    if [[ -f /etc/kernel/cmdline ]] && ! grep -q 'splash' /etc/kernel/cmdline; then
        sudo sed -i 's/$/ quiet splash/' /etc/kernel/cmdline
        done_any=1
        print_ok "Added 'quiet splash' to /etc/kernel/cmdline"
    fi

    # GRUB
    if [[ -f /etc/default/grub ]]; then
        grep -q 'splash' /etc/default/grub \
            || sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 quiet splash"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        done_any=1
        print_ok "Updated GRUB cmdline and regenerated config"
    fi

    [[ $done_any -eq 0 ]] && print_warn "No known bootloader cmdline found — add 'quiet splash' manually"
}

main() {
    print_header "Plymouth boot splash setup (opt-in)"
    print_warn "This edits mkinitcpio.conf + kernel cmdline and rebuilds the initramfs."
    print_warn "Strongly recommended to try this in a VM before a real machine."
    if [[ "${1:-}" != "--yes" ]]; then
        ask_yes_no "Continue?" || { echo "Aborted."; exit 0; }
    fi

    # 1. Plymouth itself
    sudo pacman -S --needed --noconfirm plymouth || { print_err "Could not install plymouth"; exit 1; }

    # 2. A Catppuccin Mocha theme from the AUR (try a few names; fall back later)
    if command -v yay &>/dev/null; then
        local cand
        for cand in plymouth-theme-catppuccin-mocha plymouth-theme-catppuccin-mocha-git plymouth-theme-catppuccin; do
            yay -S --needed --noconfirm "$cand" 2>/dev/null && break
        done
    else
        print_warn "yay not available — will use a built-in theme"
    fi

    # 3. Hook + cmdline
    add_plymouth_hook
    add_splash_cmdline

    # 4. Pick a theme (prefer Catppuccin, else a clean built-in) and rebuild initramfs
    local theme
    theme="$(plymouth-set-default-theme -l 2>/dev/null | grep -i catppuccin | head -1)"
    [[ -z "$theme" ]] && theme="spinner"
    print_header "Setting Plymouth theme: $theme (rebuilds initramfs)"
    sudo plymouth-set-default-theme -R "$theme" \
        && print_ok "Plymouth theme set to '$theme'" \
        || print_warn "plymouth-set-default-theme failed — run it manually"

    print_ok "Done. Reboot to see the boot splash."
}

main "$@"
