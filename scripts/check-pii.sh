#!/usr/bin/env bash
# Flag personal or network-identifying data before it lands in git history.
#
#   scripts/check-pii.sh            # staged changes (what the pre-commit hook runs)
#   scripts/check-pii.sh --all      # every tracked file (audit)
#
# Generic patterns (emails, tailnet hostnames, private/CGNAT IPv4) are built in.
# Literal personal values (real tailnet name, email, hostnames) belong in a
# local, untracked denylist so the guard never has to publish what it guards:
#   ${XDG_CONFIG_HOME:-~/.config}/pii-denylist   (one literal per line; # comments)
# Homelab Ansible (roles/linux_dotfiles) renders that file.
#
# Third-party files with legitimate addresses (licenses, fixtures) can be
# excluded with git pathspecs, one per line, in a tracked .pii-ignore.
#
# Severity comes from `git config homelab.piiGuard` (block | warn, default
# block): public repos block, private repos that might go public warn.
# Matches are reported as file:line and pattern name only, never the value.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
denylist="${XDG_CONFIG_HOME:-$HOME/.config}/pii-denylist"
severity="$(git config --get homelab.piiGuard || echo block)"

scope=(--cached)            # index content = exactly what is being committed
pathspec=()
if [ "${1-}" != "--all" ]; then
  mapfile -t pathspec < <(git diff --cached --name-only --diff-filter=ACMR)
  [ "${#pathspec[@]}" -gt 0 ] || exit 0
else
  pathspec=(.)
fi
if [ -f .pii-ignore ]; then
  while IFS= read -r p; do
    [ -n "$p" ] && [ "${p:0:1}" != "#" ] && pathspec+=(":(exclude)$p")
  done < .pii-ignore
fi

declare -A patterns=(
  [email]='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
  [tailnet-host]='[a-z0-9-]+\.ts\.net'
  [private-ipv4]='(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)'
  [cgnat-ipv4]='(^|[^0-9.])100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)'
)
# Addresses that identify nobody.
allow='noreply@|@example\.(com|org|net)|git@github\.com|@users\.noreply\.github\.com'

found=0
report() {  # stdin: git grep -n output "file:line:text"; prints location only
  while IFS=: read -r file line _; do
    printf 'pii-guard: %s:%s matches %s\n' "$file" "$line" "$1" >&2
    found=1
  done
}

for name in "${!patterns[@]}"; do
  report "$name" < <(git grep "${scope[@]}" -I -n -E -e "${patterns[$name]}" -- "${pathspec[@]}" \
    | grep -vE -- "$allow" || true)
done
if [ -r "$denylist" ]; then
  while IFS= read -r literal; do
    { [ -z "$literal" ] || [ "${literal:0:1}" = "#" ]; } && continue
    report "denylist entry" < <(git grep "${scope[@]}" -I -n -F -e "$literal" -- "${pathspec[@]}" || true)
  done < "$denylist"
fi

if [ "$found" = 1 ]; then
  if [ "$severity" = warn ]; then
    echo "pii-guard: warning only (homelab.piiGuard=warn)" >&2
    exit 0
  fi
  echo "pii-guard: blocked. Move personal values to a template/BWS, or bypass deliberately with --no-verify." >&2
  exit 1
fi
