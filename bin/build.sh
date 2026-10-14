#!/usr/bin/env bash
set -euo pipefail

host="${1-SungkyungM1X}"
if (( $# > 0 )); then
  shift
fi
case "$host" in
  SungkyungM1X|yujin|bootstrap-arm) ;;
  *) printf 'Unknown host: %s\nUsage: %s [SungkyungM1X|yujin|bootstrap-arm] [nix-build-arguments...]\n' "$host" "$0" >&2; exit 1 ;;
esac

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repo_dir"
exec nix build ".#darwinConfigurations.${host}.system" "$@"
