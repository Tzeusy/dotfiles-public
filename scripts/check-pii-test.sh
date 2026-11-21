#!/usr/bin/env bash
# Exercise scripts/check-pii.sh against throwaway repos.
#   scripts/check-pii-test.sh
# Fixture addresses are assembled at runtime so this file passes its own guard.
set -euo pipefail

guard="$(cd "$(dirname "$0")" && pwd)/check-pii.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export XDG_CONFIG_HOME="$tmp/config"   # no denylist: test the built-in patterns only
at='@'
ts="ts"
fails=0

check() {  # check <name> <expect: pass|block> <file content>
  local name="$1" expect="$2" content="$3" repo="$tmp/$1" got
  git init -q "$repo"
  printf '%s\n' "$content" > "$repo/fixture.txt"
  git -C "$repo" add fixture.txt
  if (cd "$repo" && bash "$guard") 2>"$repo.err"; then got=pass; else got=block; fi
  if [ "$got" = "$expect" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: expected $expect, got $got" >&2
    sed 's/^/     /' "$repo.err" >&2
    fails=$((fails + 1))
  fi
}

check reserved-tlds        pass  "test${at}example.invalid a${at}b.test c${at}host.localhost d${at}x.example"
check reserved-slds        pass  "user${at}example.com ops${at}mail.example.org"
check noreply-and-github   pass  "noreply${at}anthropic.com 1+u${at}users.noreply.github.com git${at}github.com"
check real-email           block "someone${at}gmail.com"
check real-beside-reserved block "test${at}example.invalid then someone${at}gmail.com"
check real-beside-example  block "user${at}example.com then someone${at}gmail.com"
check lookalike-domain     block "a${at}example.invalid.com b${at}notexample.com"
check tailnet-host         block "box.tailnet-name.${ts}.net"
check private-ipv4         block "host 192.$((160 + 8)).1.10"

[ "$fails" = 0 ] && echo "check-pii-test: all passed" || { echo "check-pii-test: $fails failed" >&2; exit 1; }
