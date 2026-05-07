# dotfiles

My personal dotfiles. Structured to work with [Homebrew](https://brew.sh/) for package management and [GNU Stow](https://www.gnu.org/software/stow/) for symlinking configs into `$HOME`.

## Homebrew

Install [Homebrew](https://brew.sh/) first, then use the bundled `Brewfile` to install every formula, cask, and tap in one go.

```sh
# Install everything listed in ./Brewfile
brew bundle

# Check which entries are still missing
brew bundle check

# Show what would be installed without actually doing it
brew bundle list

# Remove anything installed via brew that is NOT in the Brewfile
brew bundle cleanup --force

```

By default `brew bundle` looks for a `Brewfile` in the current directory, so run these commands from the repo root.

## Stow

[GNU Stow](https://www.gnu.org/software/stow/) symlinks each top-level directory (a "package") into the target directory, preserving the internal structure. Each package here mirrors the layout it should have in `$HOME` — e.g. `nvim/.config/nvim/...` becomes `~/.config/nvim/...`.

Clone the repo into your home directory, then from within `~/dotfiles` link packages one at a time.

```sh
# Link a single package into $HOME
stow nvim

# Link multiple packages
stow git zsh nvim

# Preview what stow would do without changing anything
stow -n -v nvim

# Unlink a package
stow -D nvim

# Re-link after adding/removing files in a package
stow -R nvim
```

`stow nvim` only symlinks the `nvim` config into `~/.config/nvim` — it does not touch the rest of `~/.config`.

## Devcontainers

`install.sh` is a non-interactive bootstrap script meant to be wired into the [`devcontainer` CLI](https://github.com/devcontainers/cli) via its dotfiles flags:

```sh
devcontainer up \
  --dotfiles-repository https://github.com/timswinkels/dotfiles \
  --dotfiles-target-path ~/dotfiles \
  --dotfiles-install-command install.sh
```

What it does:

- Installs `ripgrep` and `fd` via the available package manager.
- Symlinks `nvim/.config/nvim` → `~/.config/nvim`, `tmux/.config/tmux` → `~/.config/tmux`, and `git/.gitconfig` → `~/.gitconfig` (existing files are backed up to `*.bak`).
- Headlessly pre-installs nvim plugins via `Lazy! sync` so the first launch is fast.

The script is idempotent — re-running leaves correct symlinks alone.
