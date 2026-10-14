#!/bin/sh
# Run explicitly on a new Apple Silicon Mac after reviewing the provider guide.
set -eu

if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
  echo "MISSING: this bootstrap supports Apple Silicon macOS only" >&2
  exit 1
fi
if command -v nix >/dev/null 2>&1; then
  if command -v determinate-nixd >/dev/null 2>&1; then
    echo "PASS: Determinate Nix already installed"
    exit 0
  fi
  echo "CONFLICT: Nix exists without determinate-nixd; follow the provider migration guide before installing" >&2
  exit 1
fi
if command -v determinate-nixd >/dev/null 2>&1; then
  echo "CONFLICT: determinate-nixd exists but nix is unavailable; repair the installation first" >&2
  exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/determinate-bootstrap.XXXXXX")
trap 'rm -f "$work_dir/Determinate.pkg"; rmdir "$work_dir"' EXIT HUP INT TERM
curl -fL https://install.determinate.systems/determinate-pkg/stable/Universal \
  -o "$work_dir/Determinate.pkg"
test -s "$work_dir/Determinate.pkg"
/usr/sbin/pkgutil --check-signature "$work_dir/Determinate.pkg"
sudo /usr/sbin/installer -pkg "$work_dir/Determinate.pkg" -target /
echo "PASS: Determinate package installer completed; open a new shell and check nix --version"
