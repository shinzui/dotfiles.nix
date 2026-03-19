# Dotfiles management recipes
default:
  just --list

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

# Update kizamu flake input to latest
update-kizamu:
    nix flake update kizamu

# Update mori flake input to latest
update-mori:
    nix flake update mori

# Update seihou flake input to latest
update-seihou:
    nix flake update seihou

# Update rei flake input to latest
update-rei:
    nix flake update rei

# Update all personal tool flake inputs (kizamu, mori, seihou, rei)
update-tools:
    nix flake update kizamu mori seihou rei

# Check status of mori launchd agent
status-mori:
    launchctl print gui/$(id -u)/com.shinzui.mori-automate 2>&1 | head -10

# Check status of rei launchd agents
status-rei:
    launchctl print gui/$(id -u)/com.shinzui.rei-worker 2>&1 | head -10
    @echo "---"
    launchctl print gui/$(id -u)/com.shinzui.rei-subscription 2>&1 | head -10

# Check status of all personal tool agents
status-tools:
    @just status-mori
    @echo "==="
    @just status-rei
