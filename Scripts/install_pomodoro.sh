#!/usr/bin/env bash
# archScratch - build and install waybar-module-pomodoro from source

source "$(dirname "$0")/global_fn.sh"

DEST="$HOME/.local/bin/waybar-module-pomodoro"

main() {
    if [[ -f "$DEST" ]]; then
        print_ok "waybar-module-pomodoro already installed"
        return
    fi

    print_header "Building waybar-module-pomodoro"

    if ! command -v cargo &>/dev/null; then
        print_header "Initializing rustup toolchain"
        rustup default stable
        # Ensure cargo is in PATH for this shell session
        source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    git clone --depth=1 https://github.com/Andeskjerf/waybar-module-pomodoro.git "$tmpdir/pomodoro"
    (cd "$tmpdir/pomodoro" && cargo build --release)
    mkdir -p "$HOME/.local/bin"
    cp "$tmpdir/pomodoro/target/release/waybar-module-pomodoro" "$DEST"
    chmod +x "$DEST"
    rm -rf "$tmpdir"
    print_ok "waybar-module-pomodoro installed to $DEST"
}

main "$@"
