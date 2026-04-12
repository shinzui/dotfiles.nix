{ lib
, writeShellApplication
, mori
, git
, jq
, coreutils
}:

writeShellApplication {
  name = "bootstrap-repos";
  runtimeInputs = [ mori git jq coreutils ];
  text = ''
    set -euo pipefail

    usage() {
      cat <<'EOF'
    Usage: bootstrap-repos [--dry-run] [--ssh] [--filter SUBSTR] [--help]

    Clone every project registered in the local mori registry to the
    on-disk path that registry records for it. Destinations that are
    already git repos are skipped. Safe to rerun.

      --dry-run        Print planned actions; do not touch the filesystem.
      --ssh            Prefer SSH (git@github.com:OWNER/REPO.git) URLs.
      --filter SUBSTR  Only process projects whose "namespace/name"
                       contains SUBSTR.
      --help, -h       Show this help.
    EOF
    }

    dry_run=0
    use_ssh=0
    filter=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --dry-run) dry_run=1 ;;
        --ssh)     use_ssh=1 ;;
        --filter)  shift; filter="''${1:-}" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
      esac
      shift
    done

    if ! list_json="$(mori registry list --json)"; then
      echo "error: failed to query mori registry; is mori installed and its database reachable?" >&2
      exit 1
    fi

    cloned=0
    skipped=0
    errors=0
    declare -A seen_paths=()

    rows="$(printf '%s' "$list_json" | jq -r '.[] | [.namespace, .name, .path, (.docsOnly|tostring)] | @tsv')"

    while IFS=$'\t' read -r namespace name path docs_only; do
      [ -n "$namespace" ] || continue
      qname="$namespace/$name"

      if [ -n "$filter" ] && [[ "$qname" != *"$filter"* ]]; then
        continue
      fi

      if [ "$docs_only" = "true" ]; then
        echo "[docs-only] skipping $qname"
        skipped=$((skipped+1))
        continue
      fi

      if [ -n "''${seen_paths[$path]:-}" ]; then
        echo "[dup-path] skipping $qname (path $path already handled this run)"
        skipped=$((skipped+1))
        continue
      fi
      seen_paths[$path]=1

      if ! show_json="$(mori registry show "$qname" --full --json 2>/dev/null)"; then
        echo "[error] mori registry show failed for $qname" >&2
        errors=$((errors+1))
        continue
      fi

      repo_tsv="$(printf '%s' "$show_json" | jq -r '
        (.repositories[0] // {}) as $r
        | [ ($r.github // "-"), ($r.git // "-"), ($r.gitlab // "-") ]
        | @tsv
      ')"
      IFS=$'\t' read -r gh git_url gl <<< "$repo_tsv"

      url=""
      if [ "$gh" != "-" ] && [ -n "$gh" ]; then
        if [ "$use_ssh" = "1" ]; then
          url="git@github.com:$gh.git"
        else
          url="https://github.com/$gh.git"
        fi
      elif [ "$git_url" != "-" ] && [ -n "$git_url" ]; then
        url="$git_url"
      elif [ "$gl" != "-" ] && [ -n "$gl" ]; then
        if [ "$use_ssh" = "1" ]; then
          url="git@gitlab.com:$gl.git"
        else
          url="https://gitlab.com/$gl.git"
        fi
      fi

      if [ -z "$url" ]; then
        echo "[no-repo] skipping $qname"
        skipped=$((skipped+1))
        continue
      fi

      if [ -d "$path/.git" ]; then
        echo "[skip] $path (already a git repo)"
        skipped=$((skipped+1))
        continue
      fi

      if [ -e "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null || true)" ]; then
        echo "[error] $path exists and is not a git repo" >&2
        errors=$((errors+1))
        continue
      fi

      if [ "$dry_run" = "1" ]; then
        echo "[dry-run] would clone $url -> $path"
        cloned=$((cloned+1))
        continue
      fi

      mkdir -p "$(dirname "$path")"
      if git clone --quiet "$url" "$path"; then
        echo "[clone] $url -> $path"
        cloned=$((cloned+1))
      else
        echo "[error] git clone failed for $qname: $url -> $path" >&2
        errors=$((errors+1))
      fi
    done <<< "$rows"

    suffix=""
    if [ "$dry_run" = "1" ]; then suffix=" (dry-run)"; fi
    echo "Summary: $cloned cloned, $skipped skipped, $errors errors$suffix"
    if [ "$errors" -gt 0 ]; then exit 1; fi
  '';

  meta = with lib; {
    description = "Clone every project registered in the local mori registry to its recorded path";
    mainProgram = "bootstrap-repos";
    platforms = platforms.unix;
  };
}
