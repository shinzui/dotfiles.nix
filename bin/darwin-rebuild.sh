#!/usr/bin/env bash
set -euo pipefail

if (( $# == 0 )); then
  printf 'Usage: %s <SungkyungM1X|yujin|bootstrap-arm> [darwin-rebuild-arguments...]\n' "$0" >&2
  exit 1
fi
host="$1"
shift
case "$host" in
  SungkyungM1X|yujin|bootstrap-arm) ;;
  *) printf 'Unknown host: %s\nExpected SungkyungM1X, yujin, or bootstrap-arm.\n' "$host" >&2; exit 1 ;;
esac

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repo_dir"
if [[ "$host" != bootstrap-arm ]]; then
  mori_source="$repo_dir/config/xdg/mori"
  if [[ -L "$mori_source/config.dhall" || ! -f "$mori_source/config.dhall" ||
        -L "$mori_source/agents" || ! -d "$mori_source/agents" ]]; then
    printf 'Mori source files are missing or symlinks. Restore config/xdg/mori before switching.\n' >&2
    exit 1
  fi
  if [[ -L /Users/shinzui/.config/mori ]]; then
    printf 'The old ~/.config/mori whole-directory symlink must be migrated before a full switch. See docs/new-machine-bootstrap.md#source-machine-mori-migration.\n' >&2
    exit 1
  fi
  if [[ "$host" == SungkyungM1X ]] &&
     ! cmp -s /Users/shinzui/.config/mori/host-id /Users/shinzui/.local/state/dotfiles-bootstrap/sungkyung-mori-host-id; then
    printf 'Sungkyung Mori host ID is absent or differs from its protected backup; restore it before switching.\n' >&2
    exit 1
  fi
fi
if [[ ! -x ./result/sw/bin/darwin-rebuild ]]; then
  printf 'Missing built darwin-rebuild. Run ./bin/build.sh %s as the owner before switching.\n' "$host" >&2
  exit 1
fi
# Root evaluates the flake again and does not read the owner's SSH config.
# Select the workstation key explicitly, including when no agent is available.
if (( EUID == 0 )) && [[ -z "${GIT_SSH_COMMAND:-}" ]]; then
  export GIT_SSH_COMMAND='/usr/bin/ssh -i /Users/shinzui/.ssh/id_ed25519 -o IdentitiesOnly=yes'
fi
exec ./result/sw/bin/darwin-rebuild switch --flake ".#${host}" "$@"
