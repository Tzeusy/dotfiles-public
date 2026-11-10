# Public zshrc (dotfiles-public). Machine- or identity-specific config goes in
# an overlay, sourced last so it can override anything here:
#   $DOTFILES_OVERLAY/to_source/*   (default overlay: ~/.dotfiles, if it is not this repo)
#   ~/.zshrc.local                  (untracked, per machine)

# Repo root, resolved through the ~/.zshrc symlink chain.
export DOTFILES_PUBLIC="${${(%):-%x}:A:h:h}"
: "${DOTFILES_OVERLAY:=$HOME/.dotfiles}"

# OpenSpec shell completions
fpath=("$HOME/.oh-my-zsh/custom/completions" $fpath)

export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"

# Theme: https://github.com/carloscuesta/materialshell (install.sh fetches it)
ZSH_THEME="materialshell"

# Don't mark untracked files dirty: much faster status in large repos.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# `z` plugin replaced by zoxide (initialized in to_source/modern_cli)
plugins=(
  git
  virtualenv
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

for f in "$DOTFILES_PUBLIC"/to_source/*(N); do source "$f"; done

unsetopt nomatch # https://github.com/ohmyzsh/ohmyzsh/issues/31

command -v kubectl >/dev/null 2>&1 && source <(kubectl completion zsh)
export KUBECONFIG=~/.kube/config

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

alias kctx="kubectx"
alias ts="$DOTFILES_PUBLIC/useful_scripts/tmux-fzf-switch.sh"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
export VIRTUAL_ENV_DISABLE_PROMPT=0

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

# --- Overlay (private / machine-specific), last so it wins ---
if [[ -d $DOTFILES_OVERLAY/to_source && ${DOTFILES_OVERLAY:A} != "$DOTFILES_PUBLIC" ]]; then
  for f in "$DOTFILES_OVERLAY"/to_source/*(N); do source "$f"; done
fi
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
unset f
