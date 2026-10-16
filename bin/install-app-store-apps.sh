#!/bin/bash
set -euo pipefail

# Arguments: mas executable, account name, then name/ID/path/bundle-ID groups.
mas_bin="$1"
app_store_user="$2"
shift 2

run_mas() {
  if [[ "$(/usr/bin/id -un)" == "$app_store_user" ]]; then
    "$mas_bin" "$@"
  else
    /usr/bin/sudo --set-home --user="$app_store_user" "$mas_bin" "$@"
  fi
}

is_installed() {
  local bundle_id executable
  [[ -s "$app_path/Contents/_MASReceipt/receipt" ]] || return 1
  bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist" 2>/dev/null) || return 1
  [[ "$bundle_id" == "$expected_bundle_id" ]] || return 1
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Contents/Info.plist" 2>/dev/null) || return 1
  [[ -n "$executable" && -x "$app_path/Contents/MacOS/$executable" ]]
}

echo 'checking declared App Store apps...'
while (( $# > 0 )); do
  app_name="$1"
  app_id="$2"
  app_path="$3"
  expected_bundle_id="$4"
  shift 4

  if is_installed; then
    echo "  keeping $app_name ($app_id)"
    continue
  fi

  if [[ -e "$app_path" || -L "$app_path" ]]; then
    echo "Cannot verify $app_name at $app_path: expected a matching App Store bundle, executable, and receipt. Resolve this existing installation before rebuilding." >&2
    exit 1
  fi

  echo "  installing $app_name ($app_id)"
  # Redownload owned apps first. The acquisition endpoint used by `get` can
  # reject owned apps even when `install` works in the same session.
  if ! run_mas install "$app_id"; then
    # A failed command may still have installed the app; verify before trying
    # acquisition, which can require additional Apple Account authentication.
    if ! is_installed; then
      echo "  install failed; trying App Store acquisition for $app_name ($app_id)"
      if ! run_mas get "$app_id"; then
        echo "Unable to install $app_name ($app_id): both mas install and mas get failed. Review both errors above. Confirm the App Store account owns the app (paid apps must be purchased in the App Store), then rerun the rebuild." >&2
        exit 1
      fi
    fi
  fi
  if ! is_installed; then
    echo "The App Store command finished, but $app_name could not be verified at $app_path. Check the installation before rebuilding." >&2
    exit 1
  fi
done
