# Dotfiles management recipes
default:
  just --list

# Symlink Claude skills to project-local .claude/skills/
[group: 'setup']
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
[group: 'kizamu']
update-kizamu:
    nix flake update kizamu

# Update mori flake input to latest
[group: 'mori']
update-mori:
    nix flake update mori

# Check status of mori launchd agent
[group: 'mori']
status-mori:
    launchctl print gui/$(id -u)/com.shinzui.mori-automate 2>&1 | head -10

# Update seihou flake input to latest
[group: 'seihou']
update-seihou:
    nix flake update seihou

# Update rei flake input to latest
[group: 'rei']
update-rei:
    nix flake update rei

# Check status of rei launchd agents
[group: 'rei']
status-rei:
    launchctl print gui/$(id -u)/com.shinzui.rei-worker 2>&1 | head -10
    @echo "---"
    launchctl print gui/$(id -u)/com.shinzui.rei-subscription 2>&1 | head -10

# Update all personal tool flake inputs (kizamu, mori, seihou, rei)
[group: 'tools']
update-tools:
    nix flake update kizamu mori seihou rei

# Check status of all personal tool agents
[group: 'tools']
status-tools:
    @just status-mori
    @echo "==="
    @just status-rei
