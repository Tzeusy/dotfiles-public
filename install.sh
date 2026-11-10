#!/usr/bin/env bash
# Standalone installer for machines without the private overlay (e.g. a work
# laptop). Idempotent: links home_rcs/.* into ~ and fetches the oh-my-zsh
# theme/plugins and tmux plugin manager if missing. Existing real files are
# moved aside to <name>.backup.<epoch>, never overwritten.
#
#   ./install.sh            # link + fetch
#   ./install.sh --dry-run  # show what would change
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry=0; [ "${1-}" = "--dry-run" ] && dry=1
run() { if [ "$dry" = 1 ]; then echo "+ $*"; else "$@"; fi; }
stamp="$(date +%s)"

link() {  # link <src> <dest>
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then return; fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then run mv -- "$dest" "$dest.backup.$stamp"; fi
  run ln -sfn -- "$src" "$dest"
  echo "linked $dest"
}

for f in "$repo"/home_rcs/.[!.]*; do
  link "$f" "$HOME/$(basename "$f")"
done

clone() {  # clone <url> <dest>
  [ -d "$2" ] && return
  run git clone --depth 1 "$1" "$2"
}

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh missing: install it first (https://ohmyz.sh), then re-run." >&2
else
  custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone https://github.com/carloscuesta/materialshell "$custom/themes/materialshell"
  [ -e "$custom/themes/materialshell.zsh-theme" ] || \
    run ln -s materialshell/materialshell.zsh "$custom/themes/materialshell.zsh-theme"
  clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
fi
clone https://github.com/tmux-plugins/tpm "$repo/home_rcs/.tmux/plugins/tpm"

# PII guard for commits made from this clone.
run git -C "$repo" config core.hooksPath .githooks

echo "done. Machine-specific config: ~/.zshrc.local, or an overlay repo at \$DOTFILES_OVERLAY (default ~/.dotfiles)."
