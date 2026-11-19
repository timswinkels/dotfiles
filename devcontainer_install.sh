#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '[dotfiles] %s\n' "$*"; }
warn() { printf '[dotfiles] WARNING: %s\n' "$*" >&2; }

check_dependencies() {
    # Tools are expected to come from the devcontainer image
    # This is a check, not an installer — missing tools are reported as warnings
    # so the user can fix the image and rebuild.
    local missing=() present=()
    for cmd in nvim lazygit delta tmux yazi zoxide glow; do
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

setup_lazygit() {
    local src="$DOTFILES_DIR/lazygit/.config/lazygit"
    local dst="$HOME/.config/lazygit"
    mkdir -p "$HOME/.config"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            log "lazygit config symlink already correct"
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

setup_git_identity() {
    # dc-up mounts the host's ~/.gitconfig.local (user.name/email) here
    local src="/run/host-gitconfig.local"
    local dst="$HOME/.gitconfig.local"
    if [ ! -f "$src" ]; then
        warn "$src not mounted, git identity not configured"
        return 0
    fi
    ln -sf "$src" "$dst"
    log "Symlinked: $dst -> $src"
}

setup_ssh_known_hosts() {
    local known_hosts="$HOME/.ssh/known_hosts"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    for host in gitlab.com github.com; do
        if ssh-keygen -F "$host" -f "$known_hosts" >/dev/null 2>&1; then
            continue
        fi
        if ssh-keyscan -t ed25519 "$host" >> "$known_hosts" 2>/dev/null; then
            log "Added $host to known_hosts"
        else
            warn "Could not fetch host key for $host"
        fi
    done
}

detect_tz() {
    local tz=""
    if [ -L /etc/localtime ]; then
        tz="$(readlink /etc/localtime)"
        tz="${tz#*zoneinfo/}"
    fi
    case "$tz" in
        ""|/etc/localtime|UTC|Etc/UTC) tz="Europe/Amsterdam" ;;
    esac
    printf '%s' "$tz"
}

setup_zsh() {
    local dst="$HOME/.zshrc"
    local marker="# >>> dotfiles-managed (devcontainer_install.sh) >>>"
    if [ -f "$dst" ] && grep -qF "$marker" "$dst"; then
        log ".zshrc already has dotfiles-managed block, skipping"
        return 0
    fi
    local tz
    tz="$(detect_tz)"
    cat >> "$dst" <<EOF

# >>> dotfiles-managed (devcontainer_install.sh) >>>
export TZ='${tz}'
alias vim="nvim"
alias v="nvim"
alias ls="ls -la"
# Host ssh-agent socket (mounted by dc-up). Colima (forwardAgent: true) and
# Docker Desktop both expose the host agent at this path in their VM.
if [ -S /run/host-services/ssh-auth.sock ]; then
    export SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
    # The socket is owned by the VM user; chown it if this user can't write to it
    [ -w "\$SSH_AUTH_SOCK" ] || sudo -n chown "\$(id -u)" "\$SSH_AUTH_SOCK" 2>/dev/null || true
fi
eval "\$(zoxide init zsh --cmd cd)"
# <<< dotfiles-managed (devcontainer_install.sh) <<<
EOF
    log "Appended dotfiles-managed block to $dst (TZ=$tz)"
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
    check_dependencies
    setup_nvim
    setup_tmux
    setup_lazygit
    setup_git
    setup_git_identity
    setup_ssh_known_hosts
    setup_zsh
    setup_nvim_plugins
    log "Done."
    [ -L "$HOME/.config/nvim" ] && log "  nvim config: symlinked OK" || warn "  nvim config: NOT symlinked"
    [ -L "$HOME/.config/tmux" ] && log "  tmux config: symlinked OK" || warn "  tmux config: NOT symlinked"
    [ -L "$HOME/.config/lazygit" ] && log "  lazygit config: symlinked OK" || warn "  lazygit config: NOT symlinked"
}

main "$@"
