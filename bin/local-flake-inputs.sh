# Shared by the owner build and privileged activation.
load_local_flake_inputs() {
  local file="$1/.local-inputs/$2"
  local input reference extra
  local_flake_args=()
  [[ -f "$file" ]] || return 0

  while read -r input reference extra || [[ -n "$input$reference$extra" ]]; do
    [[ -z "$input" || "$input" == \#* ]] && continue
    if [[ -z "$reference" || -n "$extra" ]]; then
      printf 'Expected an input name and flake reference in %s.\n' "$file" >&2
      return 1
    fi
    local_flake_args+=(--override-input "$input" "$reference")
  done < "$file"

  if [[ -n "${local_flake_args[*]-}" ]]; then
    local_flake_args+=(--no-write-lock-file)
  fi
}
