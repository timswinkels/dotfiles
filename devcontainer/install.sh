#!/usr/bin/env bash
set -euo pipefail

# Script lives in devcontainer/, so walk one level up to get the repo root
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { printf '[dotfiles] %s\n' "$*"; }
warn() { printf '[dotfiles] WARNING: %s\n' "$*" >&2; }

check_dependencies() {
    # Tools are expected to come from the devcontainer image
    # This is a check, not an installer — missing tools are reported as warnings
    # so the user can fix the image and rebuild.
    local missing=() present=()
    for cmd in nvim fd rg lazygit tmux yazi zoxide glow; do
        if command -v "$cmd" >/dev/null 2>&1; then
            present+=("$cmd")
        else
            missing+=("$cmd")
        fi
    done
    log "Dependencies present: ${present[*]:-none}"
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing dependencies: ${missing[*]}. Add them to the image via devcontainer features or the project Dockerfile."
    fi
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
    setup_fd_symlink
    check_dependencies
    setup_nvim
    setup_tmux
    setup_git
    setup_bash
    # setup_zsh
    setup_nvim_plugins
    log "Done."
    [ -L "$HOME/.config/nvim" ] && log "  nvim config: symlinked OK" || warn "  nvim config: NOT symlinked"
    [ -L "$HOME/.config/tmux" ] && log "  tmux config: symlinked OK" || warn "  tmux config: NOT symlinked"
}

main "$@"
