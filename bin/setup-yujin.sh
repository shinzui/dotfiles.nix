#!/bin/bash
# Finish the already-enrolled Yujin bootstrap, interactively as shinzui.
set -euo pipefail

if [[ "$(id -un)" != shinzui || "$HOME" != /Users/shinzui ||
      "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  printf 'Run this as shinzui on Yujin, without sudo.\n' >&2
  exit 1
fi
fingerprint=$(/usr/bin/ssh-keygen -lf "$HOME/.ssh/agenix_ed25519.pub" -E sha256)
case "$fingerprint" in
  *' SHA256:izLyxl9dxApI31dpUv//X354mhKS1nIJZqRa/aJCzhw '*) ;;
  *) printf 'This is not the enrolled Yujin identity; stopping.\n' >&2; exit 1 ;;
esac
if [[ ! -t 0 || ! -t 1 ]]; then
  printf 'Run this in your Terminal so sudo can request your Mac password.\n' >&2
  exit 1
fi

export PATH="/nix/var/nix/profiles/default/bin:$PATH"
if [[ "${1-}" != --in-nix-shell ]]; then
  printf 'Opening the Git/Python Nix shell...\n'
  script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
  exec nix shell nixpkgs#gitMinimal nixpkgs#python3 --command \
    /bin/bash "$script_dir/$(basename -- "$0")" --in-nix-shell
fi

trap 'printf "\nSetup stopped at line %s. Fix the error above, then run ~/setup-yujin again.\n" "$LINENO" >&2' ERR
repo="$HOME/.config/dotfiles.nix"
cd -- "$repo"
auth="$repo/bin/bootstrap-nix-auth.py"
python3 "$auth" run yujin -- /usr/bin/true

printf '\nChecking prerequisites and Rei/Mori ownership...\n'
python3 "$auth" run yujin -- python3 ./bin/check-rei-mori-owner.py --expect SungkyungM1X
./bin/check-bootstrap.sh bootstrap-arm
/usr/bin/xcode-select -p
/usr/sbin/pkgutil --pkg-info com.apple.pkg.CLTools_Executables

printf '\nChecking the installer Nix configuration before activation...\n'
sudo "$(command -v python3)" - <<'PY'
import os
from pathlib import Path
import stat


def preserve(path):
    if path.is_symlink():
        if os.readlink(path) != '/etc/static/nix/nix.custom.conf':
            raise SystemExit('Unexpected nix.custom.conf symlink; inspect it before continuing.')
        return
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        return
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.geteuid():
        raise SystemExit('Unexpected nix.custom.conf file type or owner; stopping.')
    try:
        content = path.read_text()
    except UnicodeError:
        raise SystemExit('Cannot validate nix.custom.conf; contents suppressed.') from None
    if any(line.strip() and not line.lstrip().startswith('#') for line in content.splitlines()):
        raise SystemExit('nix.custom.conf contains active settings; preserve/reconcile them before continuing. Contents suppressed.')
    backup = path.with_name(path.name + '.before-nix-darwin')
    if os.path.lexists(backup):
        raise SystemExit('A nix.custom.conf backup already exists; refusing to replace it.')
    # Creating the backup with link() refuses an existing destination atomically.
    os.link(path, backup, follow_symlinks=False)
    path.unlink()
    print('Preserved the comment-only installer file as nix.custom.conf.before-nix-darwin.')


preserve(Path('/etc/nix/nix.custom.conf'))
PY

if [[ ! -L /nix/var/nix/profiles/system || ! -x /opt/homebrew/bin/brew ]]; then
  printf '\nBuilding the bootstrap profile...\n'
  python3 "$auth" run yujin -- ./bin/build.sh bootstrap-arm
  printf '\nActivating bootstrap. Enter your Mac password if prompted.\n'
  python3 "$auth" run yujin --sudo -- ./bin/darwin-rebuild.sh bootstrap-arm
fi
/opt/homebrew/bin/brew --prefix

printf '\nPreparing restricted configuration directories...\n'
directories=(
  "$HOME/.config/nhub" "$HOME/.config/ntn"
  "$HOME/.config/gcloud" "$HOME/.config/gcloud/configurations"
  "$HOME/.config/nagare" "$HOME/.config/nagare/contexts"
  "$HOME/.config/nagare/kubeconfigs" "$HOME/.kube"
)
for directory in "${directories[@]}"; do
  if [[ -L "$directory" || ( -e "$directory" && ! -d "$directory" ) ]]; then
    printf 'Conflicting configuration directory: %s\n' "$directory" >&2
    exit 1
  fi
done
/usr/bin/install -d -m 700 "${directories[@]}"
./bin/check-bootstrap.sh yujin

printf '\nBuilding the full Yujin profile. This can take a while...\n'
python3 "$auth" run yujin -- ./bin/build.sh yujin
printf '\nActivating Yujin. Enter your Mac password if prompted.\n'
python3 "$auth" run yujin --sudo -- ./bin/darwin-rebuild.sh yujin

printf '\nVerifying managed authentication before removing the bootstrap credential...\n'
sudo -v
python3 "$auth" verify yujin
python3 "$auth" cleanup yujin

printf '\nRebuild and credential handoff complete. Rei/Mori remain assigned to Sungkyung.\n'
printf 'Open a new Terminal for the managed shell. Complete any macOS or app approvals locally.\n'
