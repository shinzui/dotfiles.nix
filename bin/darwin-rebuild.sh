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
if [[ ! -x ./result/sw/bin/darwin-rebuild ]]; then
  printf 'Missing built darwin-rebuild. Run ./bin/build.sh %s as the owner before switching.\n' "$host" >&2
  exit 1
fi
exec ./result/sw/bin/darwin-rebuild switch --flake ".#${host}" "$@"
