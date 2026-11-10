#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Interactively switch to a tmux session.

Usage:
  tmux-session [SESSION]
  tmux-session [-l]
  tmux-session [-h | --help]

Examples:
  # Interactively choose a tmux session and switch to it
  tmux-session

  # List all tmux sessions
  tmux-session -l

  # Switch directly to a named session
  tmux-session work

Flags:
  -l          List all available tmux sessions
  -h, --help  Show this help message
EOF
}

fzf_missing() {
  cat <<EOF
You must install fzf to use interactive session selection:

    https://github.com/junegunn/fzf

INSTALLATION

Homebrew (macOS) and Linuxbrew (Linux):
    brew install fzf

From source (macOS, Linux):
    git clone https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install

Other installation options:
    https://github.com/junegunn/fzf#installation
EOF
}

require_tmux() {
  command -v tmux >/dev/null 2>&1 || {
    printf '%s\n' "tmux is not installed or not in PATH." >&2
    exit 1
  }
}

has_sessions() {
  tmux list-sessions >/dev/null 2>&1
}

list_sessions() {
  require_tmux
  if ! has_sessions; then
    printf '%s\n' "No tmux sessions found."
    return 0
  fi
  tmux list-sessions -F '  #S'
}

attach_or_switch() {
  local session="$1"
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

pick_session() {
  require_tmux

  command -v fzf >/dev/null 2>&1 || {
    fzf_missing
    exit 1
  }

  if ! has_sessions; then
    printf '%s\n' "No tmux sessions found." >&2
    exit 1
  fi

  local session
  session="$(
    tmux list-sessions -F '#S' |
      fzf --exit-0 --prompt='tmux session> '
  )"

  if [[ -z "$session" ]]; then
    printf '%s\n' "Aborted. Nothing has been changed."
    exit 0
  fi

  attach_or_switch "$session"
}

switch_named_session() {
  local session="$1"
  require_tmux

  if ! tmux has-session -t "$session" 2>/dev/null; then
    printf 'No such tmux session: %s\n' "$session" >&2
    exit 1
  fi

  attach_or_switch "$session"
}

main() {
  if [[ $# -eq 0 ]]; then
    pick_session
  elif [[ "$1" == "-l" ]]; then
    list_sessions
  elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
  elif [[ $# -eq 1 ]]; then
    switch_named_session "$1"
  else
    usage
    exit 1
  fi
}

main "$@"