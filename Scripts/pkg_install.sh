#!/usr/bin/env bash
# archScratch - package installation

source "$(dirname "$0")/global_fn.sh"

# Set early — used by multiple functions
ASUS_LAPTOP=false

# ─── ASUS / G14 repo ──────────────────────────────────────────────────────────

setup_asus_repo() {
    [[ "$ASUS_LAPTOP" != "true" ]] && return

    print_header "Adding [g14] ASUS Linux repo"

    # Import and locally sign the asus-linux repo signing key
    print_header "Importing asus-linux PGP signing key"
    sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
    sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
    print_ok "asus-linux signing key trusted"

    if grep -q '^\[g14\]' /etc/pacman.conf; then
        print_ok "[g14] repo already present in pacman.conf"
    else
        printf '\n[g14]\nServer = https://arch.asus-linux.org\n' \
            | sudo tee -a /etc/pacman.conf > /dev/null
        print_ok "[g14] repo added to pacman.conf"
    fi
    # Full sync+upgrade after adding the repo (avoids partial-upgrade breakage).
    sudo pacman -Syu --noconfirm || print_warn "[g14] repo sync had warnings — continuing anyway"
}

install_g14_kernel() {
    [[ "$ASUS_LAPTOP" != "true" ]] && return

    print_header "Installing linux-g14 kernel"
    sudo pacman -S --needed --noconfirm linux-g14 linux-g14-headers
    print_ok "linux-g14 + headers installed"

    # ── Bootloader entry ──────────────────────────────────────────────────────

    if [[ -d /boot/loader/entries ]]; then
        # systemd-boot
        local entry="/boot/loader/entries/arch-g14.conf"
        if [[ -f "$entry" ]]; then
            print_ok "systemd-boot entry for linux-g14 already exists"
            return
        fi

        # Detect installed microcode
        local ucode=""
        if pacman -Qi intel-ucode &>/dev/null; then
            ucode="initrd /intel-ucode.img"
        elif pacman -Qi amd-ucode &>/dev/null; then
            ucode="initrd /amd-ucode.img"
        fi

        # Determine kernel options robustly:
        #  1) copy the `options` line from an existing loader entry (what already boots), else
        #  2) reuse the running kernel's /proc/cmdline (minus BOOT_IMAGE/initrd tokens), else
        #  3) fall back to a guess and warn loudly.
        local existing root_opts=""
        existing=$(grep -L 'linux-g14' /boot/loader/entries/*.conf 2>/dev/null | head -1)
        [[ -z "$existing" ]] && existing=$(ls /boot/loader/entries/*.conf 2>/dev/null | head -1)
        if [[ -n "$existing" ]]; then
            root_opts=$(grep '^options' "$existing" | head -1 | sed 's/^options //')
        fi
        if [[ -z "$root_opts" && -r /proc/cmdline ]]; then
            root_opts=$(tr ' ' '\n' < /proc/cmdline \
                | grep -vE '^(BOOT_IMAGE|initrd)=' | paste -sd' ' -)
        fi
        if [[ -z "$root_opts" ]]; then
            root_opts="root=/dev/sda2 rw"
            print_warn "Could not detect root options — EDIT $entry before rebooting!"
        fi

        sudo tee "$entry" > /dev/null <<EOF
title   Arch Linux (linux-g14)
linux   /vmlinuz-linux-g14
${ucode}
initrd  /initramfs-linux-g14.img
options ${root_opts}
EOF
        print_ok "systemd-boot entry created: $entry"

    elif [[ -f /boot/grub/grub.cfg ]]; then
        # GRUB auto-detects kernels on regenerate
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        print_ok "GRUB config regenerated — linux-g14 entry added"
    else
        print_warn "Unknown bootloader. Manually add a boot entry for linux-g14."
    fi
}

# ─── Core installs ────────────────────────────────────────────────────────────

install_yay() {
    if command -v yay &>/dev/null; then
        print_ok "yay already installed"
        return
    fi
    print_header "Installing yay (AUR helper)"
    sudo pacman -S --needed git base-devel --noconfirm
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    print_ok "yay installed"
}

ensure_rust_toolchain() {
    # `rustup` (the pacman package) ships no default toolchain; install one now
    # so the from-source pomodoro build later has a working `cargo`.
    command -v rustup &>/dev/null || return 0
    print_header "Initializing Rust stable toolchain"
    rustup default stable 2>/dev/null || rustup toolchain install stable \
        || print_warn "rustup could not initialize a stable toolchain"
    print_ok "Rust toolchain ready"
}

rank_mirrors() {
    # Rank the fastest HTTPS mirrors before the big sync. reflector may not be on a
    # fresh base yet (it's also in pkg_pacman.lst for future runs) — skip if absent.
    command -v reflector &>/dev/null || { print_warn "reflector not installed yet — skipping mirror ranking"; return 0; }
    print_header "Ranking pacman mirrors (reflector)"
    if sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
        print_ok "Mirrorlist updated"
    else
        print_warn "reflector failed — keeping existing mirrorlist"
    fi
}

install_ruby_gems() {
    # Rails ships as a gem, not a maintained Arch package. Install it (and Bundler)
    # as user gems; ~/.local gem bin is put on PATH in .zshrc.
    command -v gem &>/dev/null || { print_warn "gem not found — skipping Ruby on Rails"; return 0; }
    if gem list -i rails &>/dev/null; then
        print_ok "Rails already installed"
        return 0
    fi
    print_header "Installing Ruby gems (Rails, Bundler)"
    if gem install --user-install --no-document rails bundler; then
        print_ok "Rails + Bundler installed (user gems)"
    else
        print_warn "Could not install Rails/Bundler gems"
    fi
}

install_pacman_packages() {
    print_header "Installing pacman packages"
    local lst="$DOTFILES_DIR/Scripts/pkg_pacman.lst"
    local pkgs
    mapfile -t pkgs < <(grep -vE '^\s*#|^\s*$' "$lst")
    pac_install "${pkgs[@]}" || print_warn "Some pacman packages were skipped (see above)."
    print_ok "Pacman package step complete"
}

install_aur_packages() {
    print_header "Installing AUR packages"
    if ! command -v yay &>/dev/null; then
        print_warn "yay not available — skipping AUR packages"
        return 0
    fi
    local lst="$DOTFILES_DIR/Scripts/pkg_aur.lst"
    local pkgs p
    mapfile -t pkgs < <(grep -vE '^\s*#|^\s*$' "$lst")
    [[ ${#pkgs[@]} -eq 0 ]] && { print_ok "No AUR packages listed"; return 0; }
    # Install one at a time so a single failing AUR build doesn't drop the rest.
    for p in "${pkgs[@]}"; do
        yay -S --needed --noconfirm "$p" || print_warn "AUR package failed: $p"
    done
    print_ok "AUR package step complete"
}

prompt_microcode() {
    print_header "CPU Microcode"
    echo -e "  Select your CPU type:"
    echo -e "  1) Intel"
    echo -e "  2) AMD"
    echo -e "  3) Skip"
    read -rp "$(echo -e "${YELLOW}  [?]${NC} Choice [1/2/3]: ")" choice
    case "$choice" in
        1) sudo pacman -S --needed --noconfirm intel-ucode && print_ok "intel-ucode installed" ;;
        2) sudo pacman -S --needed --noconfirm amd-ucode  && print_ok "amd-ucode installed"   ;;
        *) print_warn "Skipping microcode" ;;
    esac
}

prompt_nvidia() {
    print_header "NVIDIA GPU"
    if ! ask_yes_no "Do you have an NVIDIA GPU?"; then
        print_ok "Skipping NVIDIA setup"
        return
    fi

    print_header "Installing NVIDIA drivers"
    if [[ "$ASUS_LAPTOP" == "true" ]]; then
        # linux-g14 requires nvidia-open-dkms (open source kernel module)
        sudo pacman -S --needed --noconfirm nvidia-open-dkms nvidia-utils nvidia-settings vulkan-icd-loader
    else
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings vulkan-icd-loader
    fi
    print_ok "NVIDIA drivers installed"

    # NVIDIA power services (suspend/resume/hibernate)
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
    sudo systemctl enable --now nvidia-powerd 2>/dev/null || true
    print_ok "NVIDIA power services enabled"

    if [[ "$ASUS_LAPTOP" == "true" ]]; then
        print_header "Installing ASUS tools (from [g14] repo)"
        # supergfxctl is phased out per asus-linux.org — skip it
        sudo pacman -S --needed --noconfirm asusctl power-profiles-daemon rog-control-center
        print_ok "ASUS tools installed"

        # power-profiles-daemon conflicts with tlp — disable tlp, use ppd instead
        sudo systemctl disable --now tlp.service 2>/dev/null || true
        sudo systemctl enable --now power-profiles-daemon.service
        # asusd activates automatically via udev — no manual enable needed
        print_ok "power-profiles-daemon enabled, tlp disabled (they conflict)"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    # Ask about ASUS first — affects repo setup and package choices
    print_header "Hardware detection"
    if ask_yes_no "Is this an ASUS ROG/TUF laptop (needs G14 kernel + ASUS tools)?"; then
        ASUS_LAPTOP=true
        print_ok "ASUS mode enabled"
    fi

    rank_mirrors           # fastest mirrors first (no-op if reflector not present yet)
    sudo pacman -Syu --noconfirm || true
    setup_asus_repo        # adds [g14] repo before any installs (no-op if not ASUS)
    install_yay
    install_pacman_packages
    ensure_rust_toolchain
    install_ruby_gems
    install_aur_packages
    prompt_microcode
    install_g14_kernel     # installs g14 kernel + bootloader entry (no-op if not ASUS)
    prompt_nvidia
}

main "$@"
