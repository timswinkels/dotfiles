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
stow git zsh nvim lazygit

# Preview what stow would do without changing anything
stow -n -v nvim

# Unlink a package
stow -D nvim

# Re-link after adding/removing files in a package
stow -R nvim
```

`stow nvim` only symlinks the `nvim` config into `~/.config/nvim` — it does not touch the rest of `~/.config`.

### Lazygit and delta

Diffs in git and lazygit are rendered by [delta](https://github.com/dandavison/delta) (`brew "git-delta"`). Shared delta settings live in the `[delta]` section of `git/.gitconfig`; `lazygit/.config/lazygit/config.yml` adds a unified and a side-by-side renderer (cycle with `|`). If delta is missing, git falls back to `less`/`cat`.

On macOS lazygit reads its config from `~/Library/Application Support/lazygit`, so `zsh/.zshrc` exports `LG_CONFIG_FILE` to point it at the stowed `~/.config/lazygit/config.yml`. LazyVim's lazygit integration (snacks.nvim) respects this variable.

## Devcontainers

`devcontainer_install.sh` is a non-interactive bootstrap script meant to be wired into the [`devcontainer` CLI](https://github.com/devcontainers/cli) via its dotfiles flags:

```sh
devcontainer up \
  --dotfiles-repository https://github.com/timswinkels/dotfiles \
  --dotfiles-target-path ~/dotfiles \
  --dotfiles-install-command devcontainer_install.sh
```

The script targets Debian/Ubuntu Linux (uses `apt-get`). What it does:

- Checks for required CLI tools (`nvim`, `fd`, `rg`) and warns if any are missing. Tools are expected to come from the devcontainer image at build time (see `devcontainer/default-features.json`). On Debian/Ubuntu the script also bridges `fdfind` → `~/.local/bin/fd` so shell guards looking for `fd` work.
- Symlinks `nvim/.config/nvim` → `~/.config/nvim`, `tmux/.config/tmux` → `~/.config/tmux`, `lazygit/.config/lazygit` → `~/.config/lazygit`, `git/.gitconfig` → `~/.gitconfig`, and `zsh/.zshrc` → `~/.zshrc` (existing files are backed up to `*.bak`).
- Headlessly pre-installs nvim plugins via `Lazy! sync` so the first launch is fast.

The script is idempotent — re-running leaves correct symlinks alone.

### Devcontainer shortcuts

`zsh/.zshrc` defines three aliases that wrap the `devcontainer` CLI with the right flags per subcommand:

- `dcbuild` → `devcontainer build` with `--additional-features` (tools baked into the image)
- `dcup`    → `devcontainer up` with the dotfiles flags (per-user shell config & symlinks)
- `dcexec`  → `devcontainer exec` (pure shorthand)

The default features list lives in `devcontainer/default-features.json` — edit that file to change what gets baked in. The `dcbuild` alias re-reads it on every invocation. This mirrors what VS Code's `dev.containers.defaultFeatures` setting does, but on the CLI.

### Agents in herdr

Herdr detects agents by the pane's foreground process on the host, which for a devcontainer is `devcontainer`/`docker`, so an agent started from a `dc` shell shows up as a plain terminal. Start it with `dc-claude` or `dc-opencode` instead: they set `HERDR_AGENT` on the host-side command so herdr reads the pane as that agent. Herdr's session restore won't resume container sessions, since restore runs on the host.

### SSH agent and git identity

`dc-up` bind-mounts the host ssh-agent socket at `/run/host-services/ssh-auth.sock` and the `dc*` aliases set `SSH_AUTH_SOCK` to it, so `git` over SSH works inside the container without copying keys. With Colima this needs `forwardAgent: true` in `~/.colima/default/colima.yaml` (then `colima stop && colima start`): Lima then links the agent to that path in the VM — the same path Docker Desktop uses. After a Colima restart or sleep/wake the container can hold a stale socket; recreate it with `dc-rm && dc-up`.

`dc-up` also mounts a copy of `~/.gitconfig.local` (your `user.name`/`user.email`), refreshed on every run, which `devcontainer_install.sh` symlinks into the container user's home, and the script pre-seeds `known_hosts` for gitlab.com and github.com. The real file is never mounted: the host's git config includes it, so a container that could write to it could make the host run arbitrary commands.
