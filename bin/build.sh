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
source "$repo_dir/bin/local-flake-inputs.sh"
load_local_flake_inputs "$repo_dir" "$host"
exec nix build ".#darwinConfigurations.${host}.system" ${local_flake_args[@]+"${local_flake_args[@]}"} "$@"
