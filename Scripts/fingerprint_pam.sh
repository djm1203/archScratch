#!/usr/bin/env bash
# archScratch - add fingerprint auth to sudo (password stays as fallback).
# Usage: fingerprint_pam.sh [--undo]
# Safety: needs an enrolled print, backs up the file, uses "sufficient" (never "required").
# Keep a root shell open (sudo -s) in another terminal while you test.

source "$(dirname "$0")/global_fn.sh"

PAM=/etc/pam.d/sudo
LINE='auth       sufficient   pam_fprintd.so'

if [[ "${1:-}" == "--undo" ]]; then
    sudo sed -i '/pam_fprintd\.so/d' "$PAM" && print_ok "Removed fingerprint line from $PAM"
    exit $?
fi

command -v fprintd-list &>/dev/null || { print_err "fprintd-list missing — run Scripts/install_fingerprint.sh first"; exit 1; }
fprintd-list "$(id -un)" 2>/dev/null | grep -qi 'finger' \
    || { print_err "No enrolled fingerprint. Run 'fprintd-enroll' first (then fprintd-verify)."; exit 1; }

if grep -q 'pam_fprintd\.so' "$PAM"; then
    print_ok "Already configured"
    exit 0
fi

sudo cp "$PAM" "$PAM.archscratch-bak.$(date +%Y%m%d-%H%M%S)" || exit 1
# Insert before the first 'auth' line so the fingerprint is tried first.
sudo sed -i "0,/^auth/s//$LINE\nauth/" "$PAM" || exit 1
print_ok "Added fingerprint to sudo. Test in a NEW terminal: sudo -k && sudo true"
print_warn "Undo: bash $0 --undo   (or restore $PAM.archscratch-bak.*)"
