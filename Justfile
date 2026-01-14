# Dotfiles management recipes

# Symlink Claude skills to ~/.claude/commands/
symlink-claude-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    src_dir="$(pwd)/claude/commands"
    dest_dir="$HOME/.claude/commands"

    mkdir -p "$dest_dir"

    for file in "$src_dir"/*.md; do
        [ -e "$file" ] || continue
        name=$(basename "$file")
        dest="$dest_dir/$name"

        if [ -L "$dest" ]; then
            echo "Skipping $name (symlink exists)"
        elif [ -e "$dest" ]; then
            echo "Warning: $dest exists and is not a symlink, skipping"
        else
            ln -s "$file" "$dest"
            echo "Linked $name"
        fi
    done
