# Dotfiles management recipes

# Symlink Claude skills to project-local .claude/skills/
symlink-claude-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    src_dir="$(pwd)/claude/skills"
    dest_dir="$(pwd)/.claude/skills"

    mkdir -p "$dest_dir"

    for skill in "$src_dir"/*/; do
        [ -d "$skill" ] || continue
        name=$(basename "$skill")
        dest="$dest_dir/$name"

        if [ -L "$dest" ]; then
            echo "Skipping $name (symlink exists)"
        elif [ -e "$dest" ]; then
            echo "Warning: $dest exists and is not a symlink, skipping"
        else
            ln -s "$skill" "$dest"
            echo "Linked $name"
        fi
    done
