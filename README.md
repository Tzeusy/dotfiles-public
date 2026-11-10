# dotfiles-public

Shareable half of my shell setup: zsh (oh-my-zsh + [materialshell](https://github.com/carloscuesta/materialshell)),
tmux ([oh-my-tmux](https://github.com/gpakosz/.tmux) + local overrides), vim, git, and a handful of
zsh helpers. Nothing here is machine- or identity-specific; that lives in an overlay.

## Install

```bash
git clone https://github.com/Tzeusy/dotfiles-public ~/dotfiles-public
~/dotfiles-public/install.sh      # --dry-run to preview
exec zsh
```

Optional tools that `to_source/` wires up when present: fzf, ripgrep, zoxide, atuin, eza, bat, fd,
lazygit, yazi, kubecolor, delta, gh.

## Layout

| Path | Purpose |
| --- | --- |
| `home_rcs/` | Dotfiles symlinked into `~` (`.zshrc`, `.tmux.conf*`, `.vimrc`, `.gitconfig`, ...) |
| `to_source/` | Snippets sourced by `.zshrc` (aliases, keybindings, Ctrl-U pane word picker, ...) |
| `useful_scripts/` | Standalone helpers (`ts` = fzf tmux session switcher) |
| `scripts/check-pii.sh` | Pre-commit guard against emails, tailnet hosts, private IPs |

## Overlay

`.zshrc` sources, after everything else:

1. `$DOTFILES_OVERLAY/to_source/*` (default `~/.dotfiles`, skipped if that is this repo)
2. `~/.zshrc.local`

Put hostnames, tokens, site-specific aliases and PATH entries there. Git identity goes in
`~/.gitconfig.local`, which `.gitconfig` includes last.
