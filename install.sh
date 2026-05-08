#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '[dotfiles] %s\n' "$*"; }
warn() { printf '[dotfiles] WARNING: %s\n' "$*" >&2; }

SUDO=""
if [ "$(id -u)" != "0" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        warn "Not running as root and sudo not available — apt installs will likely fail"
    fi
fi

install_packages() {
    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get not found — this script targets Debian/Ubuntu Linux"
        return 1
    fi

    log "Updating apt lists..."
    $SUDO apt-get update -qq

    command -v rg >/dev/null 2>&1 \
        && log "ripgrep already installed" \
        || { log "Installing ripgrep..."; $SUDO apt-get install -y --no-install-recommends ripgrep; }

    if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
        log "Installing fd-find..."
        $SUDO apt-get install -y --no-install-recommends fd-find
    else
        log "fd already available"
    fi

    command -v zoxide >/dev/null 2>&1 \
        && log "zoxide already installed" \
        || { log "Installing zoxide..."; $SUDO apt-get install -y --no-install-recommends zoxide; }

    # eza only landed in Debian 13 / Ubuntu 24.04 repos — make it non-fatal so
    # older base images don't break the whole install.
    command -v eza >/dev/null 2>&1 \
        && log "eza already installed" \
        || { log "Installing eza..."; $SUDO apt-get install -y --no-install-recommends eza || warn "eza not available in this apt repo — skipping"; }

    # nvim's telescope-fzf-native requires make + gcc to compile
    command -v make >/dev/null 2>&1 || $SUDO apt-get install -y --no-install-recommends make
    command -v gcc  >/dev/null 2>&1 || $SUDO apt-get install -y --no-install-recommends gcc
}

setup_fd_symlink() {
    if command -v fd >/dev/null 2>&1; then
        log "fd available as 'fd'"
        return 0
    fi
    if command -v fdfind >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        export PATH="$HOME/.local/bin:$PATH"
        for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            if [ -f "$rc" ] && ! grep -q '\.local/bin' "$rc"; then
                printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
                log "Added ~/.local/bin to PATH in $rc"
            fi
        done
        log "fd symlink created: $(ls -la "$HOME/.local/bin/fd")"
    else
        warn "fdfind not found after install — fd will not be available"
    fi
}

setup_nvim() {
    local src="$DOTFILES_DIR/nvim/.config/nvim"
    local dst="$HOME/.config/nvim"
    mkdir -p "$HOME/.config"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log "nvim config symlink already correct"
            return 0
        fi
        warn "Backing up existing $dst to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    log "Symlinked: $dst -> $src"
    mkdir -p "$HOME/.nvim/undodir"
    log "Created undodir"
}

setup_tmux() {
    local src="$DOTFILES_DIR/tmux/.config/tmux"
    local dst="$HOME/.config/tmux"
    mkdir -p "$HOME/.config"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log "tmux config symlink already correct"
            return 0
        fi
        warn "Backing up existing $dst to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    log "Symlinked: $dst -> $src"
}

setup_git() {
    local src="$DOTFILES_DIR/git/.gitconfig"
    local dst="$HOME/.gitconfig"
    if [ ! -f "$src" ]; then
        warn "git/.gitconfig not found, skipping"
        return 0
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log ".gitconfig symlink already correct"
            return 0
        fi
        warn "Backing up existing $dst to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    log "Symlinked: $dst -> $src"
}

setup_bash() {
    local src="$DOTFILES_DIR/bash/bashrc.dotfiles"
    local dst="$HOME/.bashrc"
    local marker="# >>> dotfiles >>>"
    if [ ! -f "$src" ]; then
        warn "bash/bashrc.dotfiles not found, skipping"
        return 0
    fi
    [ -f "$dst" ] || touch "$dst"
    if grep -qF "$marker" "$dst"; then
        log ".bashrc dotfiles block already present"
        return 0
    fi
    cat >> "$dst" <<EOF

# >>> dotfiles >>>
[ -f "$src" ] && source "$src"
# <<< dotfiles <<<
EOF
    log "Appended dotfiles block to $dst (sourcing $src)"
}

setup_zsh() {
    local src="$DOTFILES_DIR/zsh/.zshrc"
    local dst="$HOME/.zshrc"
    if [ ! -f "$src" ]; then
        warn "zsh/.zshrc not found, skipping"
        return 0
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log ".zshrc symlink already correct"
            return 0
        fi
        warn "Backing up existing $dst to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    log "Symlinked: $dst -> $src"
}

setup_nvim_plugins() {
    if ! command -v nvim >/dev/null 2>&1; then
        log "nvim not in PATH — plugins will install on first launch"
        return 0
    fi
    log "Pre-installing nvim plugins headlessly (timeout 5m)..."
    if timeout 300 nvim --headless "+Lazy! sync" +qa 2>&1 | sed 's/^/[dotfiles] [nvim] /'; then
        log "Plugin install complete"
    else
        warn "Headless plugin install timed out or failed — will retry on first launch"
    fi
}

main() {
    log "Starting dotfiles install from $DOTFILES_DIR (user: $(id -un))"
    install_packages
    setup_fd_symlink
    setup_nvim
    setup_tmux
    setup_git
    setup_bash
    setup_zsh
    setup_nvim_plugins
    log "Done."
    log "  rg:   $(command -v rg   >/dev/null 2>&1 && rg   --version | head -1 || echo NOT FOUND)"
    log "  fd:   $(command -v fd   >/dev/null 2>&1 && fd   --version           || echo NOT FOUND)"
    log "  nvim: $(command -v nvim >/dev/null 2>&1 && nvim --version | head -1 || echo not in image)"
    [ -L "$HOME/.config/nvim" ] && log "  nvim config: symlinked OK" || warn "  nvim config: NOT symlinked"
    [ -L "$HOME/.config/tmux" ] && log "  tmux config: symlinked OK" || warn "  tmux config: NOT symlinked"
}

main "$@"
