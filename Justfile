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

# Update mina flake input to latest
[group: 'mina']
update-mina:
    nix flake update mina

# Update mori flake input to latest
[group: 'mori']
update-mori:
    nix flake update mori

# Restart mori automate daemon
[group: 'mori']
restart-mori:
    launchctl kickstart -k gui/$(id -u)/com.shinzui.mori-automate

# Check status of mori launchd agent
[group: 'mori']
status-mori:
    launchctl print gui/$(id -u)/com.shinzui.mori-automate 2>&1 | head -10

# Tail mori automate logs (stdout and stderr)
[group: 'mori']
logs-mori-automate:
    tail -f ~/.mori/logs/automate.stdout.log ~/.mori/logs/automate.stderr.log

# Tail mori postgres logs (stdout and stderr)
[group: 'mori']
logs-mori-postgres:
    tail -f ~/.mori/logs/postgres.stdout.log ~/.mori/logs/postgres.stderr.log

# Tail all mori logs
[group: 'mori']
logs-mori:
    tail -f ~/.mori/logs/*.log

# Update mori-rei-app flake input to latest
[group: 'mori-rei-app']
update-mori-rei-app:
    nix flake update mori-rei-app

# Restart mori-rei-app server
[group: 'mori-rei-app']
restart-mori-rei-app:
    launchctl kickstart -k gui/$(id -u)/com.shinzui.mori-rei-app

# Check status of mori-rei-app launchd agent
[group: 'mori-rei-app']
status-mori-rei-app:
    launchctl print gui/$(id -u)/com.shinzui.mori-rei-app 2>&1 | head -10

# Tail mori-rei-app logs (stdout and stderr)
[group: 'mori-rei-app']
logs-mori-rei-app:
    tail -f ~/.mori-rei-app/logs/server.stdout.log ~/.mori-rei-app/logs/server.stderr.log

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

# Tail rei worker logs (stdout and stderr)
[group: 'rei']
logs-rei-worker:
    tail -f ~/.rei/logs/worker.stdout.log ~/.rei/logs/worker.stderr.log

# Tail rei subscription logs (stdout and stderr)
[group: 'rei']
logs-rei-subscription:
    tail -f ~/.rei/logs/subscription.stdout.log ~/.rei/logs/subscription.stderr.log

# Tail all rei logs
[group: 'rei']
logs-rei:
    tail -f ~/.rei/logs/*.log

# Update notion-cli flake input to latest
[group: 'notion-cli']
update-notion-cli:
    nix flake update notion-cli

# Update notion-hub flake input to latest
[group: 'notion-hub']
update-notion-hub:
    nix flake update notion-hub

# Restart notion-hub subscription daemon
[group: 'notion-hub']
restart-notion-hub:
    launchctl kickstart -k gui/$(id -u)/com.shinzui.notion-hub-subscription

# Check status of notion-hub launchd agent
[group: 'notion-hub']
status-notion-hub:
    launchctl print gui/$(id -u)/com.shinzui.notion-hub-subscription 2>&1 | head -10

# Tail notion-hub subscription logs (stdout and stderr)
[group: 'notion-hub']
logs-notion-hub-subscription:
    tail -f ~/.notion-hub/logs/subscription.stdout.log ~/.notion-hub/logs/subscription.stderr.log

# Tail all notion-hub logs
[group: 'notion-hub']
logs-notion-hub:
    tail -f ~/.notion-hub/logs/*.log

# Update all personal tool flake inputs (kizamu, mina, mori, mori-rei-app, seihou, rei, notion-cli, notion-hub)
[group: 'tools']
update-tools:
    nix flake update kizamu mina mori mori-rei-app seihou rei notion-cli notion-hub

# Check status of all personal tool agents
[group: 'tools']
status-tools:
    @just status-mori
    @echo "==="
    @just status-mori-rei-app
    @echo "==="
    @just status-rei
    @echo "==="
    @just status-notion-hub
