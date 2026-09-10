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

# Update one or more shinzui Haskell projects together with `haskell-nix-dev`,
# the shared toolchain base flake they all follow.
#
# The base must move with them. Each project declares its module-owned inputs as
# `follows = "haskell-nix-dev/<name>"` (nixpkgs, flake-parts, treefmt-nix,
# pre-commit-hooks), so a project revision that expects inputs the locked base
# does not re-export cannot resolve at all:
#
#   error: input 'seihou/flake-parts' follows a non-existent input
#          'seihou/haskell-nix-dev/flake-parts'
#
# That is not recoverable by updating the project alone — `nix flake update
# seihou` touches only the seihou node and leaves the stale base in place.
#
# Bumping the base is deliberately fleet-wide: it is the single pin every
# project's nixpkgs follows, which is what keeps them on one GHC and one
# nixpkgs and lets them share the binary cache. Expect the other Haskell
# inputs to rebuild against the new base after this runs.
_update-with-base +INPUTS:
    nix flake update haskell-nix-dev {{INPUTS}}

# Update kizamu flake input to latest (moves the haskell-nix-dev base too)
[group: 'kizamu']
update-kizamu: (_update-with-base "kizamu")

# Update mina flake input to latest (moves the haskell-nix-dev base too)
[group: 'mina']
update-mina: (_update-with-base "mina")

# Update mori flake input to latest (moves the haskell-nix-dev base too)
[group: 'mori']
update-mori: (_update-with-base "mori")

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

# Update mori-rei-app flake input to latest (moves the haskell-nix-dev base too)
[group: 'mori-rei-app']
update-mori-rei-app: (_update-with-base "mori-rei-app")

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

# Update seihou flake input to latest (moves the haskell-nix-dev base too)
[group: 'seihou']
update-seihou: (_update-with-base "seihou")

# Update rei flake input to latest (moves the haskell-nix-dev base too)
[group: 'rei']
update-rei: (_update-with-base "rei")

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

# Update reiko flake input to latest (moves the haskell-nix-dev base too)
[group: 'reiko']
update-reiko: (_update-with-base "reiko")

# Update notion-cli flake input to latest (moves the haskell-nix-dev base too)
[group: 'notion-cli']
update-notion-cli: (_update-with-base "notion-cli")

# Update notion-hub flake input to latest (moves the haskell-nix-dev base too)
[group: 'notion-hub']
update-notion-hub: (_update-with-base "notion-hub")

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

# Run a PostgreSQL backup via pg_rman (full or incremental)
[group: 'postgres']
pg-backup mode="full":
    pg-backup {{mode}}

# Show the pg_rman backup catalog
[group: 'postgres']
pg-backup-show:
    pg-backup-show

# Purge PostgreSQL backups older than N days (default 7)
[group: 'postgres']
pg-backup-purge days="7":
    pg-backup-purge {{days}}

# Check status of the postgresql launchd agent
[group: 'postgres']
status-postgres:
    launchctl print gui/$(id -u)/com.shinzui.postgresql 2>&1 | head -20

# Tail the postgresql server logs (stdout and stderr)
[group: 'postgres']
logs-postgres:
    tail -f ~/.local/state/postgresql/logs/postgres.stdout.log ~/.local/state/postgresql/logs/postgres.stderr.log

# Check the local Redpanda cluster (containers and broker readiness)
[group: 'redpanda']
status-redpanda:
    redpanda-status

# Restart the Redpanda cluster (stops containers, then brings them back up)
[group: 'redpanda']
restart-redpanda:
    redpanda-down
    redpanda-up

# Tail the Redpanda broker logs (pass a container name for console)
[group: 'redpanda']
logs-redpanda:
    redpanda-logs -f

# Tail the launchd agent's own output, i.e. what redpanda-up printed at login
[group: 'redpanda']
logs-redpanda-agent:
    tail -f ~/.local/state/redpanda/logs/redpanda-up.stdout.log ~/.local/state/redpanda/logs/redpanda-up.stderr.log

# Open Redpanda Console in the default browser
[group: 'redpanda']
redpanda-ui:
    open http://redpanda.localhost

# NOTE: there is deliberately no `purge-redpanda` recipe. `redpanda-purge`
# deletes the data volume and every topic in it; a one-word just recipe is too
# easy to run by accident. Run the command directly if you mean it.

# Update all personal tool flake inputs (kizamu, mina, mori, mori-rei-app, seihou, rei, reiko, notion-cli, notion-hub)
[group: 'tools']
update-tools: (_update-with-base "kizamu" "mina" "mori" "mori-rei-app" "seihou" "rei" "reiko" "notion-cli" "notion-hub")

# Update every input that follows haskell-nix-dev, plus the base itself. Wider
# than `update-tools`: also covers the library inputs with no recipe of their
# own (kazuha, nihongo, shiki, okf). Use this after a breaking base change, so
# no project is left resolving against a base contract it does not expect.
[group: 'tools']
update-haskell-fleet: (_update-with-base "mori" "rei" "reiko" "seihou" "kizamu" "kazuha" "mina" "nihongo" "shiki" "okf" "notion-cli" "mori-rei-app" "notion-hub")

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

# Open the VictoriaLogs UI in the default browser
[group: 'logs']
logs-ui:
    open http://localhost:9428/select/vmui/

# Run an ad-hoc LogsQL query and pretty-print the response
[group: 'logs']
logs-query QUERY:
    curl -sS 'http://localhost:9428/select/logsql/query' \
      --data-urlencode "query={{QUERY}}" | jq

# Check status of the VictoriaLogs launchd agent
[group: 'logs']
status-victorialogs:
    launchctl print gui/$(id -u)/com.shinzui.victorialogs 2>&1 | head -20

# Restart the VictoriaLogs launchd agent
[group: 'logs']
restart-victorialogs:
    launchctl kickstart -k gui/$(id -u)/com.shinzui.victorialogs

# Tail the VictoriaLogs server's own stdout/stderr
[group: 'logs']
logs-victorialogs:
    tail -f ~/.local/share/victoria-logs/logs/victoria-logs.stdout.log ~/.local/share/victoria-logs/logs/victoria-logs.stderr.log

# Open the Jaeger UI backed by VictoriaTraces
[group: 'traces']
traces-ui:
    open http://localhost:16686/

# Open the VictoriaTraces built-in UI
[group: 'traces']
traces-vmui:
    open http://localhost:10428/select/vmui/

# Check status of the VictoriaTraces launchd agents
[group: 'traces']
status-victoriatraces:
    launchctl print gui/$(id -u)/com.shinzui.victoriatraces 2>&1 | head -20
    @echo "==="
    launchctl print gui/$(id -u)/com.shinzui.victoriatraces-jaeger-ui 2>&1 | head -20

# Restart the VictoriaTraces launchd agents
[group: 'traces']
restart-victoriatraces:
    launchctl kickstart -k gui/$(id -u)/com.shinzui.victoriatraces
    launchctl kickstart -k gui/$(id -u)/com.shinzui.victoriatraces-jaeger-ui

# Tail the VictoriaTraces server and Jaeger UI nginx logs
[group: 'traces']
logs-victoriatraces:
    tail -f ~/.local/share/victoria-traces/logs/*.log
